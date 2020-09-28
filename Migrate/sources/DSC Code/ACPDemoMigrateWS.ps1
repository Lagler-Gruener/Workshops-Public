Configuration ACPDemoMigrateWS
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xHyper-V'

	node ConfigureHyperV
  	{
        #Install Hyper-V
        WindowsFeature Hyper-V
        {
            Ensure = 'Present'
            Name = 'Hyper-V'
            IncludeAllSubFeature = $true

        }

        WindowsFeature Hyper-V-Tools
        {
            Ensure = 'Present'
            Name = 'Hyper-V-Tools'
            IncludeAllSubFeature = $true
            DependsOn = '[WindowsFeature]Hyper-V'
        }

        #Install Hyper-V Powershell modules
        WindowsFeature Hyper-V-PowerShell
        {
            Ensure = 'Present'
            Name = 'Hyper-V-PowerShell'
            IncludeAllSubFeature = $true
            DependsOn = '[WindowsFeature]Hyper-V'
        }


        #Konfigure Hyper-V
        File Hyper-V-TempDownload
        {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = 'C:\tempdwn'
        }

        File Hyper-V-Root-Dir
        {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = 'C:\Hyper-V'
        }

        File Hyper-V-VM-Dir
        {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = 'C:\Hyper-V\VMs'
            DependsOn = '[File]Hyper-V-Root-Dir'
        }
       

		# Ensures a VM with default settings
        xVMSwitch InternalSwitch
        {
            Ensure         = 'Present'
            Name           = 'DemoMig Nat Switch'
            Type           = 'Internal'
            DependsOn = '[WindowsFeature]Hyper-V'          
        }
		
		Script Import-UbuntuVM
    	{
			GetScript = 
			{
				@{Result = "ConfigureHyperV"}
			}	
		
			TestScript = 
			{
                if((Get-VM -Name demovmubuntu -ErrorAction SilentlyContinue).count -gt 0)
                {
                    
                    return $true;
                }
                else
                {
           		    return $false
                }
        	}	
		
			SetScript =
			{
				$zipDownload = "https://straccdemomigratewscont.blob.core.windows.net/vmimages/demovmubuntu.zip"
				$downloadedFile = "C:\tempdwn\demovmubuntu.zip"
				$vmFolder = "C:\Hyper-V\VMs\"
                
                if(!(Test-Path -Path $downloadedFile))
                {
				    Invoke-WebRequest $zipDownload -OutFile $downloadedFile                    
                }

			    Add-Type -assembly "system.io.compression.filesystem"
			    [io.compression.zipfile]::ExtractToDirectory($downloadedFile, $vmFolder)
                
                #Expand-Archive -LiteralPath $downloadedFile -DestinationPath $vmFolder
				
                $NatSwitch = Get-NetAdapter -Name "vEthernet (DemoMig Nat Switch)"
				
                if ((Get-NetIPAddress -IPAddress 192.168.0.1 -ErrorAction SilentlyContinue) -eq $null)
                {
                    New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceIndex $NatSwitch.ifIndex
                }

                if ((Get-NetNat -Name NestedVMNATnetwork -ErrorAction SilentlyContinue) -eq $null)
                {
				    New-NetNat -Name NestedVMNATnetwork -InternalIPInterfaceAddressPrefix 192.168.0.0/24 -Verbose
                }

				New-VM -Name demovmubuntu `
					   -MemoryStartupBytes 1GB `
					   -BootDevice VHD `
					   -VHDPath 'C:\Hyper-V\VMs\demovmubuntu\Virtual Hard Disks\demovmubuntu.vhdx' `
                       -Path 'C:\Hyper-V\VMs\' `
					   -Generation 1 `
				       -Switch "DemoMig Nat Switch"

			    Start-VM -Name demovmubuntu
			}
            DependsOn = '[File]Hyper-V-VM-Dir','[WindowsFeature]Hyper-V'
		}

        Script Import-WindowsVM
    	{
			GetScript = 
			{
				@{Result = "ConfigureHyperV"}
			}	
		
			TestScript = 
			{
                if((Get-VM -Name demovmwindows -ErrorAction SilentlyContinue).count -gt 0)
                {
                    
                    return $true;
                }
                else
                {
           		    return $false
                }
        	}	
		
			SetScript =
			{
				$zipDownload = "https://straccdemomigratewscont.blob.core.windows.net/vmimages/demovmwindows.zip"
				$downloadedFile = "C:\tempdwn\demovmwindows.zip"
				$vmFolder = "C:\Hyper-V\VMs\"
                
                if(!(Test-Path -Path $downloadedFile))
                {
				    Invoke-WebRequest $zipDownload -OutFile $downloadedFile
                }

			    Add-Type -assembly "system.io.compression.filesystem"
			    [io.compression.zipfile]::ExtractToDirectory($downloadedFile, $vmFolder)                		

				New-VM -Name demovmwindows `
					   -MemoryStartupBytes 4GB `
					   -BootDevice VHD `
					   -VHDPath 'C:\Hyper-V\VMs\demovmwindows\Virtual Hard Disks\demovmwindows.vhdx' `
                       -Path 'C:\Hyper-V\VMs\' `
					   -Generation 1 `
				       -Switch "DemoMig Nat Switch"


			    Start-VM -Name demovmwindows
			}
            DependsOn = '[File]Hyper-V-VM-Dir','[WindowsFeature]Hyper-V'
		}


        File MigrateDir
        {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = 'C:\ACPMigrate'
        }

        Script Download-AssessmentVM
        {
            GetScript = 
			{
				@{Result = "ConfigureHyperV"}
			}	
		
			TestScript = 
			{
                if(Test-Path "C:\ACPMigrate\AzureMigrateAppliance.zip")
                {
                    
                    return $true;
                }
                else
                {
           		    return $false
                }
        	}	
		
			SetScript =
			{
                Invoke-WebRequest "https://aka.ms/migrate/appliance/hyperv" -OutFile "C:\ACPMigrate\AzureMigrateAppliance.zip"

                Add-Type -assembly "system.io.compression.filesystem"
			    [io.compression.zipfile]::ExtractToDirectory("C:\ACPMigrate\AzureMigrateAppliance.zip", "C:\ACPMigrate\")
            }
            DependsOn = '[File]MigrateDir'
        }  
        
        # Install other tools
        Script Download-GoogleChrome
    	{
			GetScript = 
			{
				@{Result = "GoogleChrome"}
			}	
		
			TestScript = 
			{
                if(Test-Path -Path "C:\tempdwn\googlechrome.msi")
                {
                    return $true
                }
                else
                {
                    return $false
                }
        	}	
		
			SetScript =
			{
				$zipDownload = "https://straccdemomigratewscont.blob.core.windows.net/software/GoogleChromeStandaloneEnterprise64.msi"
				$downloadedFile = "C:\tempdwn\googlechrome.msi"
                
                if(!(Test-Path -Path $downloadedFile))
                {
				    Invoke-WebRequest $zipDownload -OutFile $downloadedFile                    
                }			    
			}
		}

        Package Install-Chrome
        {
            Ensure = "Present"
            Name = "Google Chrome"
            Path = "C:\tempdwn\googlechrome.msi"
            ProductId = "0F488B35-59E5-3DA0-80FA-55F3BE746A68"
            DependsOn = "[Script]Download-GoogleChrome"
        }   
        
        Script Download-Putty
    	{
			GetScript = 
			{
				@{Result = "Putty"}
			}	
		
			TestScript = 
			{
                if(Test-Path -Path "C:\tempdwn\putty.exe")
                {
                    return $true
                }
                else
                {
                    return $false
                }
        	}	
		
			SetScript =
			{
				$zipDownload = "https://straccdemomigratewscont.blob.core.windows.net/software/putty.exe"
				$downloadedFile = "C:\tempdwn\putty.exe"
                
                if(!(Test-Path -Path $downloadedFile))
                {
				    Invoke-WebRequest $zipDownload -OutFile $downloadedFile                    
                }			    
			}
		}   

        Script Download-ImpCommands
    	{
			GetScript = 
			{
				@{Result = "Commands"}
			}	
		
			TestScript = 
			{
                if(Test-Path -Path "C:\tempdwn\ImportantCommands.txt")
                {
                    return $true
                }
                else
                {
                    return $false
                }
        	}	
		
			SetScript =
			{
				$zipDownload = "https://straccdemomigratewscont.blob.core.windows.net/infos/ImportantCommands.txt"
				$downloadedFile = "C:\tempdwn\ImportantCommands.txt"
                
                if(!(Test-Path -Path $downloadedFile))
                {
				    Invoke-WebRequest $zipDownload -OutFile $downloadedFile                    
                }			    
			}
		}        
  	}
}