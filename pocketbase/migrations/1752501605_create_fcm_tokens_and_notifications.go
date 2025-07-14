package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
	m.Register(func(app core.App) error {
		// --- up migration ---
		// fcm_tokens コレクション
		usersCollection, err := app.FindCollectionByNameOrId("users")
		if err != nil {
			return err
		}
		fcmTokens := core.NewBaseCollection("fcm_tokens")
		fcmTokens.Fields.Add(&core.RelationField{
			Name:          "user",
			Required:      true,
			CascadeDelete: true,
			CollectionId:  usersCollection.Id,
		})
		fcmTokens.Fields.Add(&core.TextField{
			Name:     "token",
			Required: true,
			Max:      255,
		})
		// platformフィールドは不要になったため削除
		fcmTokens.Fields.Add(&core.AutodateField{
			Name:     "created",
			OnCreate: true,
		})
		fcmTokens.Fields.Add(&core.AutodateField{
			Name:     "updated",
			OnCreate: true,
			OnUpdate: true,
		})
		fcmTokens.AddIndex("idx_fcm_tokens_user", false, "user", "")
		if err := app.Save(fcmTokens); err != nil {
			return err
		}

		// notifications コレクション
		notifications := core.NewBaseCollection("notifications")
		notifications.Fields.Add(&core.RelationField{
			Name:          "user",
			Required:      true,
			CascadeDelete: true,
			CollectionId:  usersCollection.Id,
		})
		notifications.Fields.Add(&core.TextField{
			Name:     "title",
			Required: true,
			Max:      255,
		})
		notifications.Fields.Add(&core.TextField{
			Name:     "body",
			Required: true,
			Max:      1000,
		})
		notifications.Fields.Add(&core.TextField{
			Name: "video_url",
			Max:  255,
		})
		notifications.Fields.Add(&core.DateField{
			Name: "scheduled_at",
		})
		notifications.Fields.Add(&core.DateField{
			Name: "sent_at",
		})
		notifications.Fields.Add(&core.BoolField{
			Name: "read",
		})
		notifications.Fields.Add(&core.BoolField{
			Name: "sent",
		})
		notifications.Fields.Add(&core.AutodateField{
			Name:     "created",
			OnCreate: true,
		})
		notifications.Fields.Add(&core.AutodateField{
			Name:     "updated",
			OnCreate: true,
			OnUpdate: true,
		})
		notifications.AddIndex("idx_notifications_user", false, "user", "")
		if err := app.Save(notifications); err != nil {
			return err
		}

		// videos コレクション（動画ファイル保存用、protected、最大1GB）
		videos := core.NewBaseCollection("videos")
		videos.Fields.Add(&core.RelationField{
			Name:          "user",
			Required:      true,
			CascadeDelete: true,
			CollectionId:  usersCollection.Id,
		})
		videos.Fields.Add(&core.TextField{
			Name:     "title",
			Required: true,
			Max:      255,
		})
		videos.Fields.Add(&core.FileField{
			Name:      "file",
			Required:  true,
			MaxSelect: 1,
			MaxSize:   1024 * 1024 * 1024, // 1GB
			Protected: true,
			MimeTypes: []string{"video/mp4", "video/av1"},
		})
		videos.Fields.Add(&core.AutodateField{
			Name:     "created",
			OnCreate: true,
		})
		videos.Fields.Add(&core.AutodateField{
			Name:     "updated",
			OnCreate: true,
			OnUpdate: true,
		})
		if err := app.Save(videos); err != nil {
			return err
		}
		return nil
	}, func(app core.App) error {
		// --- down migration ---
		notifications, err := app.FindCollectionByNameOrId("notifications")
		if err == nil {
			if err := app.Delete(notifications); err != nil {
				return err
			}
		}
		fcmTokens, err := app.FindCollectionByNameOrId("fcm_tokens")
		if err == nil {
			if err := app.Delete(fcmTokens); err != nil {
				return err
			}
		}
		return nil
	})
}
