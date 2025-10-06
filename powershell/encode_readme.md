# Simple encode all .mp4/.mkv/.avi files in one folder
.\encode.ps1 -Path "D:\Movies"

# Parallel encode with 6 jobs
.\encode.ps1 -Path "D:\Movies", "E:\TV" -Parallel -Jobs 6

# Use EAC3 audio
.\encode.ps1 -Path "D:\Movies" -Codec eac3

# Dry run (WhatIf)
.\encode.ps1 -Path "D:\Movies" -WhatIf