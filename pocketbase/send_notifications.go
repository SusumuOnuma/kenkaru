package main

import (
	"context"
	"log"
	"time"

	"firebase.google.com/go/v4/messaging"
	"github.com/pocketbase/dbx"
	"github.com/pocketbase/pocketbase"
)

// RegisterSendNotificationsCron sets up the scheduled notification sender
func RegisterSendNotificationsCron(app *pocketbase.PocketBase, fcmClient *messaging.Client) {
	app.Cron().MustAdd("send_notifications", "*/2 * * * *", func() {
		log.Println("Checking for scheduled notifications...")

		records, err := app.FindRecordsByFilter(
			"notifications",
			"sent = false && scheduled_at <= {:now}",
			"-scheduled_at",
			100,
			0,
			dbx.Params{"now": time.Now()},
		)
		if err != nil {
			log.Printf("Failed to fetch notifications: %v", err)
			return
		}

		for _, rec := range records {
			userId := rec.GetString("user")
			tokens, err := app.FindRecordsByFilter(
				"fcm_tokens",
				"user = {:user}",
				"",
				10,
				0,
				dbx.Params{"user": userId},
			)
			if err != nil {
				log.Printf("Failed to fetch fcm_tokens: %v", err)
				continue
			}
			for _, tokenRec := range tokens {
				token := tokenRec.GetString("token")
				msg := &messaging.Message{
					Notification: &messaging.Notification{
						Title: rec.GetString("title"),
						Body:  rec.GetString("body"),
					},
					Token: token,
				}
				_, err := fcmClient.Send(context.Background(), msg)
				if err != nil {
					log.Printf("Failed to send FCM: %v", err)
					continue
				}
				log.Printf("Sent FCM to %s", token)
			}
			rec.Set("sent", true)
			rec.Set("sent_at", time.Now())
			if err := app.Save(rec); err != nil {
				log.Printf("Failed to update notification: %v", err)
			}
		}
	})
}
