package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
	"github.com/pocketbase/pocketbase/tools/types"
)

func init() {
	m.Register(func(app core.App) error {
		// notificationsコレクションのcreateRuleを設定
		notifications, err := app.FindCollectionByNameOrId("notifications")
		if err != nil {
			return err
		}
		notifications.CreateRule = types.Pointer("@request.auth.id = user")
		if err := app.Save(notifications); err != nil {
			return err
		}

		// fcm_tokensコレクションのcreateRuleを設定
		fcmTokens, err := app.FindCollectionByNameOrId("fcm_tokens")
		if err != nil {
			return err
		}
		fcmTokens.CreateRule = types.Pointer("@request.auth.id = user")
		if err := app.Save(fcmTokens); err != nil {
			return err
		}
		return nil
	}, func(app core.App) error {
		// down: ルールを解除
		notifications, err := app.FindCollectionByNameOrId("notifications")
		if err == nil {
			notifications.CreateRule = nil
			if err := app.Save(notifications); err != nil {
				return err
			}
		}
		fcmTokens, err := app.FindCollectionByNameOrId("fcm_tokens")
		if err == nil {
			fcmTokens.CreateRule = nil
			if err := app.Save(fcmTokens); err != nil {
				return err
			}
		}
		return nil
	})
}
