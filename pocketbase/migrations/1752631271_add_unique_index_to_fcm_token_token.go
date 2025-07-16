package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
	m.Register(func(app core.App) error {
		// up: fcm_tokens.token にユニークインデックスを追加
		fcmTokens, err := app.FindCollectionByNameOrId("fcm_tokens")
		if err != nil {
			return err
		}
		fcmTokens.AddIndex("idx_fcm_tokens_token_unique", true, "token", "")
		if err := app.Save(fcmTokens); err != nil {
			return err
		}
		return nil
	}, func(app core.App) error {
		// down: ユニークインデックスを削除
		fcmTokens, err := app.FindCollectionByNameOrId("fcm_tokens")
		if err != nil {
			return err
		}
		// インデックス名で削除
		var newIndexes []string
		for _, idx := range fcmTokens.Indexes {
			if idx != "CREATE UNIQUE INDEX idx_fcm_tokens_token_unique ON fcm_tokens (token)" {
				newIndexes = append(newIndexes, idx)
			}
		}
		fcmTokens.Indexes = newIndexes
		if err := app.Save(fcmTokens); err != nil {
			return err
		}
		return nil
	})
}
