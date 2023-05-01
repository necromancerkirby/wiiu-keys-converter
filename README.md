# How to use the powershell script

### Option 1

Specify the source path. If you dropped the script in the same folder where all keys resides you don't need to do this.
`.\disc_keys_converter.ps1 -Url "download keys url"`

### Option 2

This AutoConfirm will not prompt you for a yes or no on the source path specified.
`.\disc_keys_converter.ps1 -AutoConfirm 1 -SkipDownload 1`

If you have the keys, just create a temp folder and put them there. (temp folder must be in the same place as the script).  
After you have put the keys in the temp folder just run the `Option 2` command.

## Will this script work on linux?

I'm a linux user and this script was created on my personal machine in my spare time. Whatever distribution you use as long as you download Powershell latest it should run just fine. This should apply to macOS and of course needless to say Windows.

If powershell is giving you issues considering downloading the latest. Most Windows machines still use the 5.x.

## Do I need to install anything else?

Nope. Powershell is very self-contained in the sense that you can use C# core libraries without really needing to need a compiler or well anything which is honestly what makes it a great tool for cross-platform.

## Want to donate? I only accept XMR (Monero)

![Monero QR](./monero_qr.png)  
`89EmNU7rvyWUdjNxBfgyrQ3SSwTfeNk7bSGhwMGz2oRBZfGcKePXxHkMpCmCmY8cc9DBacMCL47WNNYy884CRM6NGS1hjTB`

# Will there be more?

Yes... eventually. It won't exactly come as tools but rather other contributions in things I want to fix but need to get familiar with the source code.
