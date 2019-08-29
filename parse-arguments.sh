echo "### Parsing command line arguments."

for i in "$@"
do
    case $i in
        # Keep --event for backwards compatibility.
        --event=*|--settings=*)
            SETTINGS_NAME="${i#*=}"
            shift
            ;;
        --project=*)
            PROJECT_NAME="${i#*=}"
            shift
            ;;
        *)
            ;;
    esac
done
