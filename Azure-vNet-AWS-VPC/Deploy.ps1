New-AzureRmResourceGroupDeployment -ResourceGroupName "MVPDay-RG1" -Mode Incremental -TemplateFile "D:\MVPDay\Azure-vNet-AWS-VPC\azuredeploy.json" -TemplateParameterFile "D:\MVPDay\Azure-vNet-AWS-VPC\azuredeploy.parameters.json"

.\AWSCreateVPC.ps1

New-AzureRmResourceGroupDeployment -ResourceGroupName "MVPDay-RG1" -Mode Incremental -TemplateFile "D:\MVPDay\Azure-vNet-AWS-VPC\azuredeploy2.json" -TemplateParameterFile "D:\MVPDay\Azure-vNet-AWS-VPC\azuredeploy.parameters.json"