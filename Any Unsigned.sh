#!/bin/bash
printf '\e[8;25;94t'
printf '\e[0;40;97m'
printf "\e]0;Fix\a"
clear

sys_lang=$(defaults read -g AppleLanguages | tr -d '[:space:]' | cut -c3-4)

if [[ "$sys_lang" == "en" ]]; then
    Success="Configuration successfully applied for:"
    Complete="Script execution completed. This window can be closed."
    NoInApplicationFolder="Error: Application"
    NoInApplicationFolderPart2="not found in the Applications folder!"
    Move="Move"
    MovePart2="to the applications folder and run the Fix file again!"
fi

NoColor='\033[0;40;97m'
BRed='\033[1;40;91m'

INPUT=$(osascript -e 'display dialog "Enter application name:" with title "Authorize App" default answer "" buttons {"Cancel", "Continue"} default button "Continue" cancel button "Cancel"' -e 'text returned of result' 2>/dev/null)

if [ $? -ne 0 ]; then exit 1; fi

GameName=$(echo "$INPUT" | xargs)
[[ "$GameName" == *.app ]] || GameName="${GameName}.app"
Game="/Applications/$GameName"
DisplayName="${GameName%.app}"

if [ -d "$Game" ]; then
    echo -e ""

    draw_centered_full_width_box() {
        local text="$1"
        local text_color="${2:-}"
        local box_color="${3:-}"
        local term_width=$(tput cols)

        text_width() {
            local str="$1"
            echo -n "$str" | sed -E 's/\x1B\[[0-9;]*[mGKH]//g' | sed 's/./x/g' | wc -c
        }

        local available_width=$((term_width - 2))
        local clean_text=$(echo -n "$text" | sed -E 's/\x1B\[[0-9;]*[mGKH]//g')
        local text_len=$(text_width "$clean_text")

        if (( text_len > available_width )); then
            local cut_pos=$((available_width - 3))
            text="${clean_text:0:$cut_pos}..."
            text_len=$(text_width "$text")
        fi

        local left_padding=$(( (available_width - text_len) / 2 ))
        local right_padding=$(( available_width - text_len - left_padding ))

        local color_reset="\033[0;40;97m"
        local box_start="${box_color:-}"
        local box_end="${box_color:+$color_reset}"
        local text_start="${text_color:-}"
        local text_end="${text_color:+$color_reset}"

        printf "${box_start}╭%*s╮${box_end}\n" "$((term_width - 2))" | tr ' ' '─'
        printf "${box_start}│${box_end}%*s${text_start}%s${text_end}%*s${box_start}│${box_end}\n" \
               "$left_padding" "" "$text" "$right_padding" ""
        printf "${box_start}╰%*s╯${box_end}\n" "$((term_width - 2))" | tr ' ' '─'
    }

    draw_centered_full_width_box "$DisplayName"
    echo -e ""

    PASSWORD=$(osascript <<APPLESCRIPT
display dialog "$DisplayName needs permission to run on this Mac.
Enter admin password to continue." ¬
    with title "$DisplayName" ¬
    default answer "" ¬
    with hidden answer ¬
    buttons {"Cancel", "Continue"} ¬
    default button "Continue" ¬
    cancel button "Cancel"
return text returned of result
APPLESCRIPT
    )

    if [ $? -ne 0 ]; then exit 1; fi

   printf '%s\n' "$PASSWORD" | sudo -S xattr -dr com.apple.quarantine "$Game"

if xattr -lr "$Game" 2>/dev/null | grep -q com.apple.quarantine; then
    osascript -e "display dialog \"Unable to remove quarantine from $DisplayName.\" with title \"$DisplayName\" buttons {\"OK\"} default button \"OK\" with icon stop"
    exit 1
fi

open "$Game"

    if [ $? -ne 0 ]; then
        osascript -e "display dialog \"Not authorized. Use admin password\" with title \"$DisplayName\" buttons {\"OK\"} default button \"OK\" with icon stop"
        exit 1
    fi

    open "$Game"

    osascript <<APPLESCRIPT
display dialog "$DisplayName authorized!" & return & "Open from " & quote & "Apps" & quote & " as normal." with title "$DisplayName" buttons {"OK"} default button "OK"
APPLESCRIPT

    osascript -e "tell application \"$DisplayName\" to quit" 2>/dev/null

    clear

    if [[ "$sys_lang" == "en" ]]; then
        echo -e ""
        echo -e "   ${NoColor}$Success"
        echo -e "   ${BRed}$Game"
        echo -e "   ${NoColor}$Complete\n"
    fi

    osascript -e 'tell application "Terminal" to close (every window whose name contains "Fix")'
    exit 0

else

    if [[ "$sys_lang" == "en" ]]; then
        echo -e ""
        echo -e "   ${NoColor}$NoInApplicationFolder ${BRed}${DisplayName}${NoColor} $NoInApplicationFolderPart2"
        echo -e "   ${NoColor}$Move ${BRed}$DisplayName${NoColor} $MovePart2\n"
    fi

    osascript -e 'tell application "Terminal" to close (every window whose name contains "Fix")'
    exit 1
fi
