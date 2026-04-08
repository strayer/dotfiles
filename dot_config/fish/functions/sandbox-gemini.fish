function sandbox-gemini
    set -lx NO_BROWSER true
    safe --add-dirs-ro="$HOME/.config/gcloud/application_default_credentials.json" gemini $argv
end
