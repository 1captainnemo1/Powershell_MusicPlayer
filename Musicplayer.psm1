
PowerShell Gallery Home
Packages
Publish
Statistics
Documentation
Sign in
Search PowerShell packages...
MusicPlayer 1.0.1
MusicPlayer.psm1
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
66
67
68
69
70
71
72
73
74
75
76
77
78
79
80
81
82
83
84
85
86
87
88
89
90
91
92
93
94
95
96
97
98
99
100
101
102
103
104
105
106
107
108
109
110
111
112
113
114
115
116
117
118
119
120
121
122
123
124
125
126
127
128
129
130
131
132
133
134
135
136
137
138
139
140
141
142
143
144
145
146
147
148
149
150
151
152
153
154
155
156
157
158
159
160
161
162
163
164
165
166
167
168
169
170
171
172
173
174
175
176
177
178
179
180
181
182
183
184
185
186
187
188
189
190
191
192
193
194
195
196
197
198
199
200
201
202
203
204
205
206
207
208
209
210
211
212
213
214
215
216
217
218
219
220
221
222
223
224
225
226
227
228
229
230
231
232
233
234
235
236
237
238
239
<#
.Synopsis
   Plays music on Windows Media Player in backgroud.
.DESCRIPTION
   Invoke-MusicPlayer Cmdlet automates Windows Media Player to play songs in Background in order (Random/Sequential) chosen by the user.
   Moreover, It generates a balloon notification in bottom Right corner of the screen, whenever a new song starts playing and continues to do that until manually stopped or it completes playing all songs.
.PARAMETER Filter
    String that can be used to filter out songs in a directory. Wildcards are allowed.
.PARAMETER Path
    Path of the Music Directory. 
    like, Music -Path C:\music\ 
.PARAMETER Shuffle
    Switch to play music in shuffle mode, default value is 'sequential'
.PARAMETER Loop
    Switch to continuously play songs in a infinite Loop.
.PARAMETER Stop
Switch to kill any instance of Music playing in backgroud.
.PARAMETER ShowPlaylist

.EXAMPLE
    PS C:\> Music C:\Music\
    
    Directory : C:\Music\
    Count : 4
    PlayDuration(in mins) : 14
    Mode : Sequential
    Current : Cheap Thrills - Vidya Vox Cover.mp3
    Next : Despacito - Luis Fonsi.mp3
   
    Example shows how to run music from by passing a music directory to the Function
.EXAMPLE
    PS C:\> play -Verbose
    VERBOSE: You've not provided a music directory. Looking for cached information from previous execution of this cmdlet
    VERBOSE: Starting a background Job to play audio files


    Directory : C:\Music\
    Count : 4
    PlayDuration(in mins) : 14
    Mode : Sequential
    Current : Cheap Thrills - Vidya Vox Cover.mp3
    Next : Despacito - Luis Fonsi.mp3

    Example shows that in case you don't provide a music directory, the function Looks for the cached information of the diretory from previous us of the function.
    Moreover, It displays the information like Count, Total play duration, and Mode chosen by the user
.EXAMPLE
    PS C:\> play -Shuffle

    Directory : C:\Music\
    Count : 4
    PlayDuration(in mins) : 14
    Mode : Shuffle
    Current : Cheap Thrills - Vidya Vox Cover.mp3
    Next : Whats My Name - Rihanna.mp3

    Choose 'Shuffle' switch to play music in shuffle mode, default value is 'sequential'.
.EXAMPLE
    PS C:\> Music -Shuffle -Loop

    Directory : C:\Music\
    Count : 4
    PlayDuration(in mins) : Infinite
    Mode : Shuffle in Loop
    Current : Lovers On The Sun - David Guetta.mp3
    Next : Cheap Thrills - Vidya Vox Cover.mp3

    Choose 'Loop' switch inorder to continuously play songs in a infinite Loop.
.EXAMPLE
    PS C:\> Music -Stop -Verbose
    VERBOSE: Stoping any Already running instance of Media in background.

    When 'Stop' switch is used any instance Music playing in backgroud stops.
#>
Function Invoke-MusicPlayer {
    [cmdletbinding()]
    Param(
        [Alias('P')]  [String] $Path,
        [Alias('F')]  [String] $Filter,
        [Alias('Sh')] [switch] $Shuffle,
        [Alias('St')] [Switch] $Stop,
        [Alias('L')]  [Switch] $Loop,
        [Alias('Pl')] [switch] $ShowPlaylist
    )

    $DefaultPath = "$env:TEMP\MusicPlayer.txt"
    If ($Stop) {
        Write-Verbose "Stoping any Already running instance of Media in background."
        Get-Job MusicPlayer -ErrorAction SilentlyContinue | Remove-Job -Force
    }
    Else {       
        #Caches Path for next time in case you don't enter path to the music directory
        If ($path) {
            $Path | out-file $DefaultPath
        }
        else {
            If ((Get-Content $DefaultPath -ErrorAction SilentlyContinue).Length -ne 0) {
                Write-Verbose "You've not provided a music directory. Looking for cached information from previous execution of this cmdlet"
                $path = Get-Content $DefaultPath

                If (-not (Test-Path $Path)) {
                    Write-Warning "Please provide a path to a music directory.`nFound a cached directory `"$Path`" from previous use, but that too isn't accessible!"
                    # Mark Path as Empty string, If Cached path doesn't exist
                    $Path = ''     
                }
            }
            else {
                Write-Warning "Please provide a path to a music directory."
            }
        }
 
        #initialization Script for back ground job
        $init = {
            # Function to calculate duration of song in Seconds
            Function Get-SongDuration($FullName) {
                $Shell = New-Object -COMObject Shell.Application
                $Folder = $shell.Namespace($(Split-Path $FullName))
                $File = $Folder.ParseName($(Split-Path $FullName -Leaf))
                        
                [int]$h, [int]$m, [int]$s = ($Folder.GetDetailsOf($File, 27)).split(":")
                        
                $h * 60 * 60 + $m * 60 + $s
            }

            # Converts seconds to HH:mm:ss string format
            Function ConvertTo-HHmmss($Seconds) {
                $Time = New-TimeSpan -Seconds $Seconds
                "{0:D2}:{1:D2}:{2:D2}" -f $Time.Hours, $Time.Minutes, $Time.Seconds
            }
                    
            # Function to Notify Information balloon message in system Tray
            Function Show-NotifyBalloon($Message) {
                [system.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null            
                $Global:Balloon = New-Object System.Windows.Forms.NotifyIcon            
                $Balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -id $pid | Select-Object -ExpandProperty Path))                    
                $Balloon.BalloonTipIcon = 'Info'           
                $Balloon.BalloonTipText = $Message            
                $Balloon.BalloonTipTitle = 'Now Playing'            
                $Balloon.Visible = $true            
                $Balloon.ShowBalloonTip(1000)
            }
                    
            Function PlayMusic($Path, $Shuffle, $Loop, $Filter, $ShowPlaylist) {
                # Calling required assembly
                Add-Type -AssemblyName PresentationCore
    
                # Instantiate Media Player Class
                $MediaPlayer = New-Object System.Windows.Media.Mediaplayer
                        
                # Crunching the numbers and Information
                $FileList = Get-ChildItem $Path -Recurse -Filter $Filter -Include *.mp* | Select-Object fullname, @{n = 'Duration'; e = {get-songduration $_.fullname}}
                $FileCount = ($FileList | Measure-Object).count
                $TotalPlayDuration = [Math]::Round(($FileList.duration | Measure-Object -Sum).sum / 60)
                        
                # Condition to identifed the Mode chosed by the user
                if ($Shuffle) {
                    $Mode = "Shuffle"
                    $FileList = $FileList | Sort-Object {Get-Random}  # Find the target Music Files and sort them Randomly
                }
                Else {
                    $Mode = "Sequential"
                }
                        
                # Check If user chose to play songs in Loop
                If ($Loop) {
                    $Mode = $Mode + " in Loop"
                    $TotalPlayDuration = "Infinite"
                }
                        
                If ($FileList) {
                    If ($FileCount -gt 1) {
                        $Current = Split-Path $FileList[0].fullname -Leaf
                        $Next = Split-Path $FileList[1].fullname -Leaf
                    }
                    ElseIf ($FileCount -eq 1) {
                        $Current = Split-Path $FileList.fullname -Leaf
                        $Next = $null
                        $FileCount = '1'
                    }

                    [PSCustomObject] @{
                        Directory    = $Path
                        Count        = $FileCount
                        'PlayDuration(in mins)' = [String]$TotalPlayDuration
                        Mode         = $Mode
                        Current      = $Current
                        Next         = $Next
                        Playlist     = $FileList | Foreach-Object { [PSCustomObject] @{ FullName = $_.FullName; Duration = $(ConvertTo-HHmmss $_.duration) } }
                    }
                }
                else {
                    Throw "No music files found in directory:`"$path`" that matches Filter: $Filter ." 
                }
                        
                Do {
                    $FileList |ForEach-Object {
                        $CurrentFile = $(Split-Path $_.fullname -Leaf)
                        $Message = "File: {0} `nPlayDuration: {1}`nMode: {2}" -f $CurrentFile, $(ConvertTo-HHmmss (Get-SongDuration $_.fullname)), $Mode            
                        $MediaPlayer.Open($_.FullName)                    # 1. Open Music file with media player
                        $MediaPlayer.Play()                                # 2. Play the Music File
                        Show-NotifyBalloon ($Message)                   # 3. Show a notification balloon in system tray
                        Start-Sleep -Seconds $_.duration                # 4. Pause the script execution until song completes
                        $MediaPlayer.Stop()                             # 5. Stop the Song
                        $Balloon.Dispose(); $Balloon.visible = $false                           
                    }
                }While ($Loop) # Play Infinitely If 'Loop' is chosen by user
            }
        }

        # Removes any already running Job, and start a new job, that looks like changing the track
        If ($(Get-Job Musicplayer -ErrorAction SilentlyContinue)) {
            Get-Job MusicPlayer -ErrorAction SilentlyContinue |Remove-Job -Force
        }

        # Run only if path was Defined or retrieved from cached information
        If ($Path) {
            Write-Verbose "Starting a background Job to play audio files"
            Start-Job -Name MusicPlayer -InitializationScript $init -ScriptBlock {playmusic $args[0] $args[1] $args[2] $args[3] $args[4]} -ArgumentList $path, $Shuffle, $Loop, $Filter, $ShowPlaylist | Out-Null
            Start-Sleep -Seconds 3       # Sleep to allow media player some breathing time to load files
            $Results = Receive-Job -Name MusicPlayer 
            $Results | Select-Object Directory, Count, 'PlayDuration(in mins)', Mode, Current, Next
            If ($ShowPlaylist){
                $Results.Playlist | Format-Table -AutoSize
            }
        }
    }
    
}

Set-Alias -Name Music -Value Invoke-MusicPlayer
Set-Alias -Name Play -Value Invoke-MusicPlayer


# Exporting the members and their aliases
Export-ModuleMember -Function "Invoke-MusicPlayer" -Alias *
