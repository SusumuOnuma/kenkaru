// package main

// import (
//     "log"
//     "os"

//     "github.com/pocketbase/pocketbase"
//     "github.com/pocketbase/pocketbase/apis"
//     "github.com/pocketbase/pocketbase/core"
// )

// func main() {
//     app := pocketbase.New()

//     app.OnServe().BindFunc(func(se *core.ServeEvent) error {
//         // serves static files from the provided public dir (if exists)
//         se.Router.GET("/{path...}", apis.Static(os.DirFS("./pb_public"), false))

//         return se.Next()
//     })

//     if err := app.Start(); err != nil {
//         log.Fatal(err)
//     }
// }

package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/core"
	"google.golang.org/api/option"
)

var fcmClient *messaging.Client // FCMクライアントをグローバル変数として保持

func init() {
	// PocketBaseの起動前にFCMクライアントを初期化します
	// serviceAccountKey.json のパスを正しく指定してください
	opt := option.WithCredentialsFile("serviceAccountKey.json")
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		log.Fatalf("error initializing Firebase app: %v", err)
	}

	fcmClient, err = app.Messaging(context.Background())
	if err != nil {
		log.Fatalf("error getting Messaging client: %v", err)
	}
	log.Println("FCM client initialized successfully.")
}

func main() {
	app := pocketbase.New()

	// PocketBaseのサーバーが起動する前にカスタムAPIルートを追加します
	app.OnServe().BindFunc(func(e *core.ServeEvent) error {
		// POST /api/send-fcm-test
		e.Router.POST("/api/send-fcm-test", func(re *core.RequestEvent) error {
			w := re.Response
			r := re.Request

			w.Header().Set("Content-Type", "application/json")

			if fcmClient == nil {
				json.NewEncoder(w).Encode(map[string]interface{}{"error": "FCM client not initialized"})
				return nil
			}

			var req struct {
				Token string `json:"token"`
				Title string `json:"title"`
				Body  string `json:"body"`
			}
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				w.WriteHeader(http.StatusBadRequest)
				json.NewEncoder(w).Encode(map[string]interface{}{"error": err.Error()})
				return nil
			}

			message := &messaging.Message{
				Notification: &messaging.Notification{
					Title: req.Title,
					Body:  req.Body,
				},
				Token: req.Token,
			}

			response, err := fcmClient.Send(context.Background(), message)
			if err != nil {
				log.Printf("Failed to send FCM message: %v", err)
				w.WriteHeader(http.StatusInternalServerError)
				json.NewEncoder(w).Encode(map[string]interface{}{"error": "Failed to send FCM message", "details": err.Error()})
				return nil
			}

			log.Printf("Successfully sent FCM message: %s", response)
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(map[string]interface{}{"message": "FCM notification sent successfully", "response": response})
			return nil
		})
		return e.Next()
	})

	// PocketBaseサーバーを起動
	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}
