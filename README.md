# PSGISP
This Powershell Module contains different functions for Active Directory, Microsoft 365 and more.
This module is also published on the powershellgallery: https://www.powershellgallery.com/packages/PSGISP

## Active Directory
### Import-BulkGPO
If you export multiple GPOs they want have have the correct and again import, they wan't have the correct GPO Name. This function is able to get the correct Name out of the Manifest XML File, which is an automatically created and hidden File.

After the GPOs are backup up, the folder will look like this.

![image](https://user-images.githubusercontent.com/114616565/194756533-bc2f63ac-d832-470b-b860-155dd49fcba9.png)

If you would import the GPO like this, the name of the GPO would be the original UID. My function will extract and set the real GPO name from the Manifest.XML file.
```powershell
Import-BulkGPO -Path .\Desktop\GPO
```
![Screenshot_20221009_142812](https://user-images.githubusercontent.com/114616565/194756881-08cd2e1b-fb48-4613-acbe-92ff958991be.png)

Now the GPOs are imported correctly.
![image](https://user-images.githubusercontent.com/114616565/194757024-57ce831c-d8b4-4c90-8baa-b19aac399c65.png)

### Get-ADUserPermission
This function will export users and their groupmembership.
By default every user and every group is exported.
```powershell
Get-ADUserPermission
```
![image](https://user-images.githubusercontent.com/114616565/195150542-29ac9868-f140-4f59-bd9b-6b0347e4e7dd.png)


It is possible to choose the users and groups with parameters User and Group.
```powershell
Get-ADUserPermission -User user1,user2 -Group group1,group2
```
![image](https://user-images.githubusercontent.com/114616565/194775615-96f94672-0a0e-4af8-86b6-8a1c41f880cd.png)

### Set-ADUserPassword
This function sets random generated passwords for specific users.
```powershell
Set-ADUserPassword -User gisp -PasswordLength 12
```
![image](https://user-images.githubusercontent.com/114616565/194776336-b2a63053-4448-4f88-82c6-d119b93d2b7f.png)

To see the decrypted password you need the following command.
```powershell
$user.GetNetworkCredential().password
```
![image](https://user-images.githubusercontent.com/114616565/194776409-9a1e04e4-69a7-48cd-8721-50a192ac0aec.png)

### Import-PrintGPO
This function will import printer to the GPO.
It is mandatory, that a GPO with one Printer is already added!
![image](https://user-images.githubusercontent.com/114616565/194777089-a9369c90-6b6d-41e0-b414-3487535a66cb.png)

If the Print GPO is prepared you can use the command to add the printers.
```powershell
Import-PrintGPO -GPO "printer" -Printer "\\printserver\printer1","\\printserver\printer2" -Action create -DefaultPrinter -GroupFilter "group1"
```
![image](https://user-images.githubusercontent.com/114616565/194777154-387c8ef7-1a35-4b8a-963c-3a7599a3a22d.png)

Result:

![image](https://user-images.githubusercontent.com/114616565/194777178-a4e52518-740c-453c-83fa-14090977816f.png)

### Export-ADUser
This function can be used to export AD user to an object.
```powershell
Export-ADUser -User "user1","user2" -AdditionalProperty "sid","whenCreated"
```
![image](https://user-images.githubusercontent.com/114616565/194777522-7b79b6ca-ac6c-40ce-ba88-f1783c7e8ada.png)

### Import-ADUser
This function can import the exported users from the command Export-ADUser.
```powershell
Import-ADUser -UserObject $userobject
```
![image](https://user-images.githubusercontent.com/114616565/194778084-097a1721-d22d-4d6c-9657-bbb448012aa7.png)

## Microsoft 365
### Get-ExchangeOnlineMailboxPermission
This function will export mailbox permission from Exchange Online into a object.
```powershell
Get-ExchangeOnlineMailboxPermission -Mailbox user1@domain.ch,user2.domain.ch
```

### Get-ExchangeOnlineCalendarPermission
This function will export calender permission from Exchange Online into a object.
```powershell
Get-ExchangeOnlineCalendarPermission -Mailbox user1@domain.ch,user2.domain.ch
```

### New-AzureADAccess
This function will create an ceritifcate based AzureAD access.
With the parameter AzureADDirectoryRole it is possible to choose the permission the application will get.
```powershell
New-AzureADAccess -AzureADDirectoryRole Global Reader -CertLifetime 2
```

## Tools
### Get-RandomString
This functions creates random strings. It is possible to generate Secure Strings.
```powershell
Get-RandomString -Length 23 -SecureString
```
![image](https://user-images.githubusercontent.com/114616565/194757684-cfba9edd-6195-4ace-a179-f7abf924b251.png)

### Join-Table
This function can be used to combine two objects into a table.
In this example I am going to use AD User and Groups to show the purpose of this function.

This Object which is used for the rows.
![image](https://user-images.githubusercontent.com/114616565/195150828-c28c15dd-36e0-4b06-95be-4c6dfbd10369.png)


This Object is used for columns. The Property Name is used for the Title of the Columns. 
![image](https://user-images.githubusercontent.com/114616565/194774750-b9c66d66-8a21-4184-b6dc-640ee587a024.png)

If you use the Parameter FieldValueUnrelated, every Field will will have the same content.
```powershell
Join-Table -Row $user -RowTitle "Name" -RowIdentifier "MemberOf" -Column $group -ColumnTitle "Name" -ColumnIdentifier "DistinguishedName" -FieldValueUnrelated "Name"
```
![image](https://user-images.githubusercontent.com/114616565/195151040-2b29aa5a-4e9d-4932-b447-a176e5a9355d.png)


If you use the Parameter FieldValue, every Field will have specific content from the column Object.
```powershell
Join-Table -Row $user -RowTitle "Name" -RowIdentifier "MemberOf" -Column $group -ColumnTitle "Name" -ColumnIdentifier "DistinguishedName" -FieldValue $true
```
![image](https://user-images.githubusercontent.com/114616565/195151155-c1937ae5-d343-4404-87e5-44390210dff2.png)
