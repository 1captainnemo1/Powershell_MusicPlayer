#Author :#Captain_Nemo
function m_player
{
import-module .\Musicplayer.psm1;

[String]$path=Read-Host "Input Path to Yer music";
$Shuff=$False;
$shuff_choice=Read-Host "Wana shuffle??? Y/N"
if($shuff_choice -like (('Y') -or ('y') -or ("Yes")))
{
$Shuff=$true;
}
$loop=$false;
$loop_choice=Read-Host "Wana loop??? Y/N"
if($loop_choice -like (('Y') -or ('y') -or ("Yes")))
{
$loop=$true;
}

Invoke-MusicPlayer -Path:$path -ShowPlaylist:$True -Loop:$loop -Shuffle:$Shuff
}
function DrawScreenBorders
{
  $cur = new-object System.Management.Automation.Host.Coordinates
  $cur.x=0
  $cur.y=0
  
  for ($x=0; $x -lt $host.ui.rawui.windowsize.width; $x++)
  {
    $cur.x=$x
    $cur.y=0
    $host.ui.rawui.cursorposition = $cur
    write-host -foregroundcolor black -backgroundcolor white  "                       JAMES ROXXZ"
    $cur = new-object System.Management.Automation.Host.Coordinates
    $cur.x=100
    $cur.y=90
    $incr=5
	do{
    write-host -foregroundcolor black -backgroundcolor white "                        JAMES ROXXZ"
	$incr--
     }while($incr -gt 0);
    $cur.y=$host.ui.rawui.windowsize.height-1
    $host.ui.rawui.cursorposition = $cur
    write-host -foregroundcolor black -backgroundcolor white -nonewline "#@#@"
    
  }
  
  for ($y=0; $y -lt $host.ui.rawui.windowsize.height-1; $y++)
  {
    $cur.y=$y
    $cur.x=0
    $host.ui.rawui.cursorposition = $cur
    write-host -foregroundcolor black -backgroundcolor white -nonewline "#"

    $cur.x=$host.ui.rawui.windowsize.width-1
    $host.ui.rawui.cursorposition = $cur
    write-host -foregroundcolor black -backgroundcolor white -nonewline "#"
    
  }  
}
cls
$ui=(get-host).ui
$rui=$ui.rawui
$rui.BackgroundColor="Black"
$rui.ForegroundColor="Red"
DrawScreenBorders;
m_player;

