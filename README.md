# 使用 Terraform 來部署 Azure

## 環境說明

使用 Terraform 來部署與管理 Azure 其實有數種方式可以使用，在本篇直接在本地安裝 Azure CLI 搭配 Terraform 來進行操作，所以最基本的設定必須要做 Terraform、Azure CLI、IDE 的安裝。另外就是我們會建立 Azure 服務主體，來授予 Terraform 在 Azure 上的權限，完成後就可以開始進行後續的自動化部署與維運管理管裡<br>

- 電腦環境
  - OS : macOS Monterey 12.3<br>
  - IDE : Visual Studio Code<br>
    https://code.visualstudio.com/download<br>
  - Cloud Shell : Azure CLI<br>
    https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos<br>
- Azure 權限設定<br>
  - Azure 服務主體<br>
    https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli<br>

# 安裝 Azure CLI
在 ＭacOS 環境中 Azure CLI 可以透過 Homebrew 來進行安裝，如果還未安裝可以參考 [homebrew 官方說明](https://brew.sh/)，如果您已經設定好此工具，請執行以下命令，此命令會更新 brew 存放庫並且進行 Azure CLI 的安裝：<br>
```
brew update && brew install azure-cli
```
完成後，可以直接在 Terminal 輸入以下指令來驗證是否安裝成功：<br>
```
az version
```
成功後即可看到以下回覆資訊：<br>
```
{
  "azure-cli": "2.34.1",
  "azure-cli-core": "2.34.1",
  "azure-cli-telemetry": "1.0.6",
  "extensions": {}
}
```
# 安裝 Terraform

安裝 Terraform 本篇一樣使用 homebrew 這個套件來進行安裝，在 Terminal 輸入以下指令進行安裝：<br>
```
brew install terraform
```

# 使用 Azure CLI 登入

在這個部分可以持續使用 Terminal 繼續進行操作，但本篇會透過 Vscode 所內建的 Terminal 介面直接進行操作，這部分可以自行選擇要使用哪種方式。<br>

登入之前您必須確認幾件事情：<br>
  1. 確保自己的帳號與訂用帳戶有進行關聯，您必須是`參與者`才能建立 Azure 服務資源<br>
  2. 後續在建立服務主體時確保自己帳號的權限為`擁有者`或`使用者存取系統管理員`的權限，如果您沒有這兩個其中之一的權限，就會收到錯誤訊息<br>
  3. 登入 Azure CLI 後，務必要確認 TenantId、SubscriptionId 是不是您進行部署或管理所提供的<br>

確認後即可開始執行以下操作：<br>

- 首先在 Terminal 介面中執行 `az login`，之後會自動開啟網頁<br>
- 選擇您具有上述權限的帳號進行登入，並且能在您的 Terminal 中看到帳務資訊<br>
  ```
  [
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "您的TenantId",
    "id": "您的訂用帳戶id",
    "isDefault": true,
    "managedByTenants": [],
    "name": "您的訂用帳戶名稱",
    "state": "Enabled",
    "tenantId": "您的目錄ID",
    "user": {
      "name": "Brian.Hsing@kyndryl.com",
      "type": "user"
    }
  }
  ]
  ```
# 使用 Azure CLI 建立服務主體

請輸入下方命令列建立服務主體，主要是會在 Azure AD 註冊應用程式，並且給予此應用程式參與者的角色，才能透過 Terraform 進行部署與維運，其中的 `<service_principal_name>` 您可以自訂名稱：<br>
```
az ad sp create-for-rbac --name <service_principal_name> --role Contributor --scopes "/subscriptions/<subscription id>"
```

完成後您將可以得到`appId`、`password`、`tenant`、`displayname`等數值，請務必保留這些數值，稍後會需要用到：<br>
```
{
  "appId": "您的appId",
  "displayName": "您的displayName",
  "password": "您的password",
  "tenant": "您的tenant"
}
```
接下來就是將上述的資訊新增至環境變數，當然如果您只是要簡單進行測試，也可以略過這個步驟，將相關資訊加入到 Terraform 的 mail.tf 中：<br>
```
export ARM_SUBSCRIPTION_ID="<您的訂用帳戶id>"
export ARM_TENANT_ID="<您的tenant>"
export ARM_CLIENT_ID="<您的appId>"
export ARM_CLIENT_SECRET="<您的password>"
```

# 撰寫 Terraform 建立資源群組

- 撰寫第一個 Terraform 程式碼，用於建立 Azure 資源群組，檔案名稱為 `main.tf`：<br>

    ```
    terraform {

    required_version = ">=0.12"
    
    required_providers {
        azurerm = {
        source = "hashicorp/azurerm"
        version = "~>2.0"
        }
    }
    }

    # 用於測試使用，如非測試練習，請不要這些資訊寫在檔案內，否則就會被看光啦
    provider "azurerm" {
    features {}

    subscription_id   = "<您的訂用帳戶id>"
    tenant_id         = "<您的tenant>"
    client_id         = "<您的appId>"
    client_secret     = "<您的password>"
    }

    # 建立一個名叫 terraform-rg 的資源群組，並且位於東亞
    resource "azurerm_resource_group" "rg" {
    name      = "terraform-rg"
    location  = "eastasia"
    }
    ```
- 初始化 Terraform 並且下載建立 Azure 資源群組所需要的模組<br>
  ```
  terraform init
  ```
- 套用 Terraform 在 Azure 環境中部署資源群組<br>
  ```
  terraform apply
  ```
- 完成後輸入此命令驗證是否已完成建立 `az group list`，如果成功會回傳以下資訊：<br>
  ```
  [
  {
    "id": "/subscriptions/你的訂用帳戶ID/resourceGroups/terraform-rg",
    "location": "eastasia",
    "managedBy": null,
    "name": "terraform-rg",
    "properties": {
      "provisioningState": "Succeeded"
    },
    "tags": {},
    "type": "Microsoft.Resources/resourceGroups"
  }
  ]
  ```
