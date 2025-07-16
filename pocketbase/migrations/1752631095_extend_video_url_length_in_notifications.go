package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
	m.Register(func(app core.App) error {
		// up: notifications.video_url の最大長を2048に拡張
		notifications, err := app.FindCollectionByNameOrId("notifications")
		if err != nil {
			return err
		}
		videoUrlField := notifications.Fields.GetByName("video_url")
		if videoUrlField == nil {
			return nil // フィールドがなければ何もしない
		}
		if textField, ok := videoUrlField.(*core.TextField); ok {
			textField.Max = 2048
		}
		if err := app.Save(notifications); err != nil {
			return err
		}
		return nil
	}, func(app core.App) error {
		// down: notifications.video_url の最大長を255に戻す
		notifications, err := app.FindCollectionByNameOrId("notifications")
		if err != nil {
			return err
		}
		videoUrlField := notifications.Fields.GetByName("video_url")
		if videoUrlField == nil {
			return nil
		}
		if textField, ok := videoUrlField.(*core.TextField); ok {
			textField.Max = 255
		}
		if err := app.Save(notifications); err != nil {
			return err
		}
		return nil
	})
}
