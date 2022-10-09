# PSGISP
## Active Directory
### Import-BulkGPO
If you export multiple GPOs they want have have the correct and again import, they wan't have the correct GPO Name. This function is able to get the correct Name out of the Manifest XML File, which is an automatically created and hidden File.

After the GPOs are backup up, the folder will look like this.

![image](https://user-images.githubusercontent.com/114616565/194756533-bc2f63ac-d832-470b-b860-155dd49fcba9.png)

If you would import the GPO like this, the name of the GPO would be the original UID. My function will extract and set the real GPO name from the Manifest.XML file.

![Screenshot_20221009_142812](https://user-images.githubusercontent.com/114616565/194756881-08cd2e1b-fb48-4613-acbe-92ff958991be.png)

Now the GPOs are imported correctly.
![image](https://user-images.githubusercontent.com/114616565/194757024-57ce831c-d8b4-4c90-8baa-b19aac399c65.png)

### Get-ADUserPermission


## Microsoft 365


## Tools
### Get-RandomString
This functions creates random strings. It is possible to generate Secure Strings.
![image](https://user-images.githubusercontent.com/114616565/194757684-cfba9edd-6195-4ace-a179-f7abf924b251.png)

### Join-Table
This function can be used to combine two objects into a table.
In this example I am going to use AD User and Groups to show the purpose of this function.

![image](https://user-images.githubusercontent.com/114616565/194774695-e3658f41-e44e-4d64-be87-32aa744162b1.png)

![image](https://user-images.githubusercontent.com/114616565/194774750-b9c66d66-8a21-4184-b6dc-640ee587a024.png)

![image](https://user-images.githubusercontent.com/114616565/194774799-0c107842-c534-4ce8-87f6-959878b6536e.png)

![image](https://user-images.githubusercontent.com/114616565/194774838-faae3ede-78d8-45a5-a11d-efdff495a6cf.png)
