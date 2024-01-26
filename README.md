
<img src="https://firebase.google.com/static/docs/cloud-messaging/images/diagram-FCM.png"/>

# Installation

## Postman
Click [here](https://www.bing.com/ck/a?!&&p=6fb8e51bfd5c010eJmltdHM9MTcwNjE0MDgwMCZpZ3VpZD0yMjM5NWU2OC0zZTFjLTY3YjgtMDQ4MC00YTZjM2Y0YTY2NTEmaW5zaWQ9NTQ5OA&ptn=3&ver=2&hsh=3&fclid=22395e68-3e1c-67b8-0480-4a6c3f4a6651&psq=postman&u=a1aHR0cHM6Ly93d3cucG9zdG1hbi5jb20vZG93bmxvYWRzLw&ntb=1) to download and install postman

## Flutter
Flutter is Google's SDK for crafting beautiful, fast user experiences for mobile, web, and desktop from a single codebase. Flutter works with existing code, is used by developers and organizations around the world, and is free and open source.

- [Flutter Installation](https://docs.flutter.dev/get-started/install)
- [Documentation](https://docs.flutter.dev/)



## API Reference

#### Get all items

```http
  POST https://{{resource_name}}.openai.azure.com/openai/deployments/{{deployment_name}}/chat/completions?api-version={{api_version}}&api-key={{api_key}}
```

| Parameter | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `api-key` | `string` | **Required**. Your API key |
| `api-version` | `string` | **Required**. Your API version |
| `resource_name` | `string` | **Required**. Your resource name in azure |
| `deployment_name` | `string` | **Required**. deployment name such as gpt model |

### body
```bash
{
    "message": [
        {
            "role": "system",
            "content": "You are a helpful assistant."
        },
        {
            "role": "user",
            "content": "What is the color of apple?"
        }
    ],
    "max_tokens": 0,
    "temperature": 1,
    "top_p": 1,
    "stop": null,
    "presence_penalty": 0,
    "frequency_penalty": 0
}
```
## Setup
Go to file lib/models/ai_chat.dart
replace {{YOUR_OPEN_AI_ENDPOINT+API_KEY}}" with your endpoint that was created on Azure Portal


## Demo

Type to your terminal:

```
Flutter run
```
