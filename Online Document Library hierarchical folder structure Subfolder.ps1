# folder count

# Function to get the number of subfolders (ignoring files) recursively
Function Get-SPOFolderStats
{
    [cmdletbinding()]

    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Folder]$Folder
    )
    
    # Get Sub-folders of the folder
    Get-PnPProperty -ClientObject $Folder -Property ServerRelativeUrl, Folders | Out-Null

    # Get the SiteRelativeUrl
    $Web = Get-PnPWeb -Includes ServerRelativeUrl
    $SiteRelativeUrl = $Folder.ServerRelativeUrl -replace "$($web.ServerRelativeUrl)", [string]::Empty

    # Calculate subfolder count only (no file count)
    $SubFolderCount = Get-PnPFolderItem -FolderSiteRelativeUrl $SiteRelativeUrl -ItemType Folder | Measure-Object | Select -ExpandProperty Count

    # Fetch the List Item corresponding to the folder
    $ListItem = Get-PnPListItem -List $ListName | Where-Object { $_["FileRef"] -eq $Folder.ServerRelativeUrl }

    # Check if the list item exists and update the FolderCount field
    if ($ListItem) {
        Set-PnPListItem -List $ListName -Identity $ListItem.Id -Values @{"FolderCount" = $SubFolderCount}
        Write-Host "Updated FolderCount for $($Folder.ServerRelativeUrl): $SubFolderCount"
    } else {
        Write-Host "List item for folder $($Folder.ServerRelativeUrl) not found."
    }

    # Process Sub-folders recursively
    ForEach($SubFolder in $Folder.Folders)
    {
        Get-SPOFolderStats -Folder $SubFolder
    }
}

# Set the SharePoint Site URL and List Name
$SiteURL = "https://futurrizoninterns.sharepoint.com/sites/MentalHealthCareWebApplication1"
$ListName = "CustomDocumentLibrary"  # Name of your document library

# Connect to SharePoint Online using Web Login
Connect-PnPOnline -URL $SiteURL -UseWebLogin

# Fetch the Document Library and start counting subfolders
$Library = Get-PnPList -Identity $ListName -Includes RootFolder

# Call the Function to Get the Library Statistics - Number of subfolders at each level
$FolderStats = $Library.RootFolder | Get-SPOFolderStats

Write-Host "Folder-wise statistics updated successfully!"

