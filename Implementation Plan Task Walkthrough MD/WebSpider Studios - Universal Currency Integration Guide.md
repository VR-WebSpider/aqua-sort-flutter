# WebSpider Studios - Universal Currency Integration Guide

This guide explains how to connect other games made by WebSpider Studios (using **Unity**, **Unreal Engine**, **Godot**, or custom web stacks) to the live 7-Tier Universal Currency System.

---

## 🌐 HTTP REST API Specifications

The currency system is powered by database RPC (Remote Procedure Call) functions hosted on Supabase. Any game engine that can send HTTP requests can access and modify user balances.

### Base Configuration
- **API URL**: `https://zpwwjdiwcucwfuzyuiqu.supabase.co/rest/v1/rpc`
- **Required Headers**:
  - `apikey`: `YOUR_SUPABASE_ANON_KEY`
  - `Authorization`: `Bearer USER_ACCESS_TOKEN` (The JWT token of the logged-in user)
  - `Content-Type`: `application/json`

---

### 1. Fetching Balances (`get_webspider_currency_v1`)

Fetches all 7 coin balances in a single JSON object.

- **Method**: `POST`
- **Endpoint**: `https://zpwwjdiwcucwfuzyuiqu.supabase.co/rest/v1/rpc/get_webspider_currency_v1`
- **Payload**:
  ```json
  {
    "p_user_id": "USER_UUID"
  }
  ```
- **Response Format (`200 OK`)**:
  ```json
  {
    "brass": 100,
    "copper": 200,
    "silver": 50,
    "gold": 10,
    "diamond": 0,
    "jade": 0,
    "obsidian": 0
  }
  ```

---

### 2. Updating Balances (`update_webspider_currency_v1`)

Credits (positive amount) or debits (negative amount) a specific balance. Safely locks the row during execution and checks for insufficient funds.

- **Method**: `POST`
- **Endpoint**: `https://zpwwjdiwcucwfuzyuiqu.supabase.co/rest/v1/rpc/update_webspider_currency_v1`
- **Payload**:
  ```json
  {
    "p_user_id": "USER_UUID",
    "p_currency_type": "gold",
    "p_amount": -5,
    "p_reason": "undo_purchase",
    "p_game_id": "lost_arrow_unity"
  }
  ```
  - **`p_currency_type`**: `'brass'`, `'copper'`, `'silver'`, `'gold'`, `'diamond'`, `'jade'`, or `'obsidian'`.
  - **`p_game_id`**: A string identifier for auditing (e.g. `'lost_arrow_unity'`, `'unreal_shooter'`).
- **Response Format (`200 OK`)**:
  Returns the new balance (integer) of that currency tier.
- **Error Response (`400 Bad Request`)**:
  If the balance is insufficient, returns:
  ```json
  {
    "message": "Insufficient gold coins. Balance: 3, Required deduction: 5"
  }
  ```

---

## 🛠 Integration Code Snippets

### 1. Unity (C#)

```csharp
using System;
using System.Text;
using System.Collections;
using UnityEngine;
using UnityEngine.Networking;

public class WebSpiderWalletManager : MonoBehaviour
{
    private const string BaseUrl = "https://zpwwjdiwcucwfuzyuiqu.supabase.co/rest/v1/rpc";
    private const string AnonKey = "YOUR_SUPABASE_ANON_KEY";

    [Serializable]
    public class UpdateCurrencyPayload
    {
        public string p_user_id;
        public string p_currency_type;
        public int p_amount;
        public string p_reason;
        public string p_game_id;
    }

    public void SpendCoins(string userId, string userToken, string type, int amount, string reason, string gameId)
    {
        StartCoroutine(UpdateCurrencyRoutine(userId, userToken, type, amount, reason, gameId));
    }

    private IEnumerator UpdateCurrencyRoutine(string userId, string token, string type, int amount, string reason, string gameId)
    {
        string endpoint = $"{BaseUrl}/update_webspider_currency_v1";

        var payload = new UpdateCurrencyPayload
        {
            p_user_id = userId,
            p_currency_type = type,
            p_amount = amount,
            p_reason = reason,
            p_game_id = gameId
        };

        string jsonPayload = JsonUtility.ToJson(payload);
        
        using (UnityWebRequest request = new UnityWebRequest(endpoint, "POST"))
        {
            byte[] bodyRaw = Encoding.UTF8.GetBytes(jsonPayload);
            request.uploadHandler = new UploadHandlerRaw(bodyRaw);
            request.downloadHandler = new DownloadHandlerBuffer();
            
            request.SetRequestHeader("Content-Type", "application/json");
            request.SetRequestHeader("apikey", AnonKey);
            request.SetRequestHeader("Authorization", $"Bearer {token}");

            yield return request.SendWebRequest();

            if (request.result == UnityWebRequest.Result.Success)
            {
                int newBalance = int.Parse(request.downloadHandler.text);
                Debug.Log($"Successfully updated balance! New {type} balance: {newBalance}");
            }
            else
            {
                Debug.LogError($"Failed to update currency: {request.error} | Response: {request.downloadHandler.text}");
            }
        }
    }
}
```

---

### 2. Unreal Engine (C++)

Add the `"HTTP"` and `"Json"` modules to your project's `.Build.cs` file.

```cpp
#include "HttpModule.h"
#include "Interfaces/IHttpRequest.h"
#include "Interfaces/IHttpResponse.h"
#include "Dom/JsonObject.h"
#include "Serialization/JsonSerializer.h"

void AWalletManager::SpendCurrency(FString UserId, FString Token, FString Type, int32 Amount, FString Reason, FString GameId)
{
    FHttpModule* Http = &FHttpModule::Get();
    TSharedRef<IHttpRequest, ESPMode::ThreadSafe> Request = Http->CreateRequest();
    
    Request->SetURL(TEXT("https://zpwwjdiwcucwfuzyuiqu.supabase.co/rest/v1/rpc/update_webspider_currency_v1"));
    Request->SetVerb(TEXT("POST"));
    Request->SetHeader(TEXT("Content-Type"), TEXT("application/json"));
    Request->SetHeader(TEXT("apikey"), TEXT("YOUR_SUPABASE_ANON_KEY"));
    Request->SetHeader(TEXT("Authorization"), FString::Printf(TEXT("Bearer %s"), *Token));

    TSharedRef<FJsonObject> JsonObject = MakeShared<FJsonObject>();
    JsonObject->SetStringField(TEXT("p_user_id"), UserId);
    JsonObject->SetStringField(TEXT("p_currency_type"), Type);
    JsonObject->SetNumberField(TEXT("p_amount"), Amount);
    JsonObject->SetStringField(TEXT("p_reason"), Reason);
    JsonObject->SetStringField(TEXT("p_game_id"), GameId);

    FString RequestBody;
    TSharedRef<TJsonWriter<>> Writer = TJsonWriterFactory<>::Create(&RequestBody);
    FJsonSerializer::Serialize(JsonObject, Writer);
    
    Request->SetContentAsString(RequestBody);
    Request->OnProcessRequestComplete().BindUObject(this, &AWalletManager::OnUpdateCurrencyComplete);
    Request->ProcessRequest();
}

void AWalletManager::OnUpdateCurrencyComplete(FHttpRequestPtr Request, FHttpResponsePtr Response, bool bWasSuccessful)
{
    if (bWasSuccessful && Response.IsValid() && Response->GetResponseCode() == 200)
    {
        int32 NewBalance = FCString::Atoi(*Response->GetContentAsString());
        UE_LOG(LogTemp, Log, TEXT("Currency updated successfully! New Balance: %d"), NewBalance);
    }
    else
    {
        UE_LOG(LogTemp, Error, TEXT("Failed to update currency. Response: %s"), *Response->GetContentAsString());
    }
}
```

---

### 3. Godot (GDScript)

```gdscript
extends Node

const BASE_URL = "https://zpwwjdiwcucwfuzyuiqu.supabase.co/rest/v1/rpc/update_webspider_currency_v1"
const ANON_KEY = "YOUR_SUPABASE_ANON_KEY"

func spend_currency(user_id: String, token: String, currency_type: String, amount: int, reason: String, game_id: String):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_request_completed)
	
	var headers = [
		"Content-Type: application/json",
		"apikey: " + ANON_KEY,
		"Authorization: Bearer " + token
	]
	
	var payload = {
		"p_user_id": user_id,
		"p_currency_type": currency_type,
		"p_amount": amount,
		"p_reason": reason,
		"p_game_id": game_id
	}
	
	var json_payload = JSON.stringify(payload)
	var err = http_request.request(BASE_URL, headers, HTTPClient.METHOD_POST, json_payload)
	if err != OK:
		push_error("An error occurred making the HTTP request.")

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var new_balance = int(body.get_string_from_utf8())
		print("Currency updated! New balance: ", new_balance)
	else:
		print("Failed to update currency. Code: ", response_code)
```
