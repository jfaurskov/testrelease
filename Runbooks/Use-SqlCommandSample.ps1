<#
.SYNOPSIS
    Outputs the number of records in the specified SQL Server database table.

.
    runffning this rffunbook. Make sure the SQL Server allows incoming connections from Azure services
	by selecting 'Allow Windows Azure Services' on the SQL Server configuration page in Azure.
f
    This runbook also requires an Automation Credential asset be created before the runbook is
    run, which stores the username and password of an account with access to the SQL Server.
    That credential should be referenced for the SqlCredential parameter of this runbook.

.PARAMETER SqlServer
    String name of the SQL Server to connect to

.PARAMETER SqlServerPort
    Integer port to connect to the SQL Server on

.PARAMETER Database
    String name of the SQL Server database to connect to

.PARAMETER Table
    String name of the database table to output the number of records of 

.PARAMETER SqlCredential
    PSCredential containing a username and password with access to the SQL Server  

.EXAMPLE
    Use-SqlCommandSample -SqlServer "somesqlserver.cloudapp.net" -SqlServerPort 1433 -Database "SomeDatabaseName" -Table "SomeTableName" - SqlCredential $SomeSqlCred

.NOTES
    AUTHOR: System Center Automation Team
    LASTEDIT: Jan 31, 2014 
#>

workflow Use-SqlCommandSample
{
    <#param(
        [parameter(Mandatory=$True)]
        [string] $SqlServer,
        
        [parameter(Mandatory=$False)]
        [int] $SqlServerPort = 1433,
        
        [parameter(Mandatory=$True)]
        [string] $Database,
        
        [parameter(Mandatory=$True)]
        [string] $Table,
        
        [parameter(Mandatory=$True)]
        [PSCredential] $SqlCredential
    )
    #>

$SqlServer = 'kkmigrationmachine.database.windows.net'
$SqlServerPort = 1433
$Database = 'migrationobjects'
$Table = 'UserMigrationQueue'
$SQLCredential = get-AutomationPSCredential -name 'dbconnection'
$SQLCommand = "SELECT top 2 username,userdomain from dbo.$Table where UserStatus = 0"
#Fixme input to return dataset or single value (count)


    # Get the username and password from the SQL Credential
    $SqlUsername = $SqlCredential.UserName
    $SqlPass = $SqlCredential.GetNetworkCredential().Password
    
    inlinescript {
        $env:ComputerName

        # Define the connection to the SQL Database
        $Conn = New-Object System.Data.SqlClient.SqlConnection("Server=tcp:$using:SqlServer,$using:SqlServerPort;Database=$using:Database;User ID=$using:SqlUsername;Password=$using:SqlPass;Trusted_Connection=False;Encrypt=True;Connection Timeout=30;")
        
        # Open the SQL connection
        $Conn.Open()

        # Define the SQL command to run. In this case we are getting the number of rows in the table
        "Mycommand: $Using:SQLCommand"
        $Cmd=new-object system.Data.SqlClient.SqlCommand($Using:SQLCommand, $Conn)
        $Cmd.CommandTimeout=10

        # Execute the SQL command
        $Ds=New-Object system.Data.DataSet
        $Da=New-Object system.Data.SqlClient.SqlDataAdapter($Cmd)
        [void]$Da.fill($Ds)

        # Output content of the rows
        #$Ds.Tables.Rows
        $ds.Tables | foreach {$UserName=$_.UserName; $UserDomain = $_UserDomain; "Do something with $UserName and $UserDomain"}
        # Close the SQL connection - fixme probably move to calling runbook
        $Conn.Close()
    }
}