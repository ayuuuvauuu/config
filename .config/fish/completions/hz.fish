# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_hz_global_optspecs
    string join \n q/quiet h/help V/version
end

function __fish_hz_needs_command
    # Figure out if the current invocation already has a command.
    set -l cmd (commandline -opc)
    set -e cmd[1]
    argparse -s (__fish_hz_global_optspecs) -- $cmd 2>/dev/null
    or return
    if set -q argv[1]
        # Also print the command, so this can be used to figure out what it is.
        echo $argv[1]
        return 1
    end
    return 0
end

function __fish_hz_using_subcommand
    set -l cmd (__fish_hz_needs_command)
    test -z "$cmd"
    and return 1
    contains -- $cmd[1] $argv
end

complete -c hz -n "__fish_hz_needs_command" -s q -l quiet -d 'Print only errors and prompts'
complete -c hz -n "__fish_hz_needs_command" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c hz -n "__fish_hz_needs_command" -s V -l version -d 'Print version'
complete -c hz -n "__fish_hz_needs_command" -f -a "extract" -d 'Extract an archive, removing it progressively'
complete -c hz -n "__fish_hz_needs_command" -f -a "x" -d 'Extract an archive, removing it progressively'
complete -c hz -n "__fish_hz_needs_command" -f -a "check" -d 'Show the space plan for an archive without modifying it'
complete -c hz -n "__fish_hz_needs_command" -f -a "c" -d 'Show the space plan for an archive without modifying it'
complete -c hz -n "__fish_hz_needs_command" -f -a "list" -d 'List the entries of an archive'
complete -c hz -n "__fish_hz_needs_command" -f -a "l" -d 'List the entries of an archive'
complete -c hz -n "__fish_hz_needs_command" -f -a "test" -d 'Verify every entry of an archive without writing files'
complete -c hz -n "__fish_hz_needs_command" -f -a "t" -d 'Verify every entry of an archive without writing files'
complete -c hz -n "__fish_hz_needs_command" -f -a "restore" -d 'Restore a partially extracted archive to a standard archive'
complete -c hz -n "__fish_hz_needs_command" -f -a "completions" -d 'Print a shell completion script'
complete -c hz -n "__fish_hz_needs_command" -f -a "man" -d 'Print the man page (roff)'
complete -c hz -n "__fish_hz_needs_command" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hz -n "__fish_hz_using_subcommand extract" -s o -l output -d 'Destination folder [default: a folder named after the archive, next to it]. With several archives, each one is extracted into this folder' -r -F
complete -c hz -n "__fish_hz_using_subcommand extract" -s p -l password -d 'Password for an encrypted archive. If omitted, HatchZip prompts for it with hidden input, which is preferred: this value is visible to other programs' -r
complete -c hz -n "__fish_hz_using_subcommand extract" -l keep-free -d 'Disk space reserved during extraction, so the disk never fills completely' -r
complete -c hz -n "__fish_hz_using_subcommand extract" -l keep-archive -d 'Keep the archive: extract without removing anything, like a standard extraction. Free space is required for all extracted files'
complete -c hz -n "__fish_hz_using_subcommand extract" -l replace -d 'Replace files that already exist in the destination folder. They are moved into a .hatchzip-replaced folder there and deleted when the extraction completes'
complete -c hz -n "__fish_hz_using_subcommand extract" -l skip-existing -d 'Keep files that already exist in the destination folder. The archive\'s copies of them are extracted and then discarded, so when the archive is removed, they are not kept anywhere'
complete -c hz -n "__fish_hz_using_subcommand extract" -l verify-first -d 'Verify every entry before modifying the archive'
complete -c hz -n "__fish_hz_using_subcommand extract" -s y -l yes -d 'Skip the confirmation prompt (required outside a terminal, unless --keep-archive is given)'
complete -c hz -n "__fish_hz_using_subcommand extract" -s q -l quiet -d 'Print only errors and prompts'
complete -c hz -n "__fish_hz_using_subcommand extract" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c hz -n "__fish_hz_using_subcommand extract" -s V -l version -d 'Print version'
complete -c hz -n "__fish_hz_using_subcommand x" -s o -l output -d 'Destination folder [default: a folder named after the archive, next to it]. With several archives, each one is extracted into this folder' -r -F
complete -c hz -n "__fish_hz_using_subcommand x" -s p -l password -d 'Password for an encrypted archive. If omitted, HatchZip prompts for it with hidden input, which is preferred: this value is visible to other programs' -r
complete -c hz -n "__fish_hz_using_subcommand x" -l keep-free -d 'Disk space reserved during extraction, so the disk never fills completely' -r
complete -c hz -n "__fish_hz_using_subcommand x" -l keep-archive -d 'Keep the archive: extract without removing anything, like a standard extraction. Free space is required for all extracted files'
complete -c hz -n "__fish_hz_using_subcommand x" -l replace -d 'Replace files that already exist in the destination folder. They are moved into a .hatchzip-replaced folder there and deleted when the extraction completes'
complete -c hz -n "__fish_hz_using_subcommand x" -l skip-existing -d 'Keep files that already exist in the destination folder. The archive\'s copies of them are extracted and then discarded, so when the archive is removed, they are not kept anywhere'
complete -c hz -n "__fish_hz_using_subcommand x" -l verify-first -d 'Verify every entry before modifying the archive'
complete -c hz -n "__fish_hz_using_subcommand x" -s y -l yes -d 'Skip the confirmation prompt (required outside a terminal, unless --keep-archive is given)'
complete -c hz -n "__fish_hz_using_subcommand x" -s q -l quiet -d 'Print only errors and prompts'
complete -c hz -n "__fish_hz_using_subcommand x" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c hz -n "__fish_hz_using_subcommand x" -s V -l version -d 'Print version'
complete -c hz -n "__fish_hz_using_subcommand check" -s o -l output -d 'Destination folder [default: a folder named after the archive, next to it]. With several archives, each one is extracted into this folder' -r -F
complete -c hz -n "__fish_hz_using_subcommand check" -s p -l password -d 'Password for an encrypted archive. If omitted, HatchZip prompts for it with hidden input, which is preferred: this value is visible to other programs' -r
complete -c hz -n "__fish_hz_using_subcommand check" -l keep-free -d 'Disk space reserved during extraction, so the disk never fills completely' -r
complete -c hz -n "__fish_hz_using_subcommand check" -l keep-archive -d 'Keep the archive: extract without removing anything, like a standard extraction. Free space is required for all extracted files'
complete -c hz -n "__fish_hz_using_subcommand check" -l replace -d 'Replace files that already exist in the destination folder. They are moved into a .hatchzip-replaced folder there and deleted when the extraction completes'
complete -c hz -n "__fish_hz_using_subcommand check" -l skip-existing -d 'Keep files that already exist in the destination folder. The archive\'s copies of them are extracted and then discarded, so when the archive is removed, they are not kept anywhere'
complete -c hz -n "__fish_hz_using_subcommand check" -s q -l quiet -d 'Print only errors and prompts'
complete -c hz -n "__fish_hz_using_subcommand check" -s h -l help -d 'Print help'
complete -c hz -n "__fish_hz_using_subcommand check" -s V -l version -d 'Print version'
complete -c hz -n "__fish_hz_using_subcommand c" -s o -l output -d 'Destination folder [default: a folder named after the archive, next to it]. With several archives, each one is extracted into this folder' -r -F
complete -c hz -n "__fish_hz_using_subcommand c" -s p -l password -d 'Password for an encrypted archive. If omitted, HatchZip prompts for it with hidden input, which is preferred: this value is visible to other programs' -r
complete -c hz -n "__fish_hz_using_subcommand c" -l keep-free -d 'Disk space reserved during extraction, so the disk never fills completely' -r
complete -c hz -n "__fish_hz_using_subcommand c" -l keep-archive -d 'Keep the archive: extract without removing anything, like a standard extraction. Free space is required for all extracted files'
complete -c hz -n "__fish_hz_using_subcommand c" -l replace -d 'Replace files that already exist in the destination folder. They are moved into a .hatchzip-replaced folder there and deleted when the extraction completes'
complete -c hz -n "__fish_hz_using_subcommand c" -l skip-existing -d 'Keep files that already exist in the destination folder. The archive\'s copies of them are extracted and then discarded, so when the archive is removed, they are not kept anywhere'
complete -c hz -n "__fish_hz_using_subcommand c" -s q -l quiet -d 'Print only errors and prompts'
complete -c hz -n "__fish_hz_using_subcommand c" -s h -l help -d 'Print help'
complete -c hz -n "__fish_hz_using_subcommand c" -s V -l version -d 'Print version'
complete -c hz -n "__fish_hz_using_subcommand list" -s p -l password -d 'Password for an encrypted archive. If omitted, HatchZip prompts for it with hidden input, which is preferred: this value is visible to other programs' -r
complete -c hz -n "__fish_hz_using_subcommand list" -s q -l quiet -d 'Print only errors and prompts'
complete -c hz -n "__fish_hz_using_subcommand list" -s h -l help -d 'Print help'
complete -c hz -n "__fish_hz_using_subcommand list" -s V -l version -d 'Print version'
complete -c hz -n "__fish_hz_using_subcommand l" -s p -l password -d 'Password for an encrypted archive. If omitted, HatchZip prompts for it with hidden input, which is preferred: this value is visible to other programs' -r
complete -c hz -n "__fish_hz_using_subcommand l" -s q -l quiet -d 'Print only errors and prompts'
complete -c hz -n "__fish_hz_using_subcommand l" -s h -l help -d 'Print help'
complete -c hz -n "__fish_hz_using_subcommand l" -s V -l version -d 'Print version'
complete -c hz -n "__fish_hz_using_subcommand test" -s p -l password -d 'Password for an encrypted archive. If omitted, HatchZip prompts for it with hidden input, which is preferred: this value is visible to other programs' -r
complete -c hz -n "__fish_hz_using_subcommand test" -s q -l quiet -d 'Print only errors and prompts'
complete -c hz -n "__fish_hz_using_subcommand test" -s h -l help -d 'Print help'
complete -c hz -n "__fish_hz_using_subcommand test" -s V -l version -d 'Print version'
complete -c hz -n "__fish_hz_using_subcommand t" -s p -l password -d 'Password for an encrypted archive. If omitted, HatchZip prompts for it with hidden input, which is preferred: this value is visible to other programs' -r
complete -c hz -n "__fish_hz_using_subcommand t" -s q -l quiet -d 'Print only errors and prompts'
complete -c hz -n "__fish_hz_using_subcommand t" -s h -l help -d 'Print help'
complete -c hz -n "__fish_hz_using_subcommand t" -s V -l version -d 'Print version'
complete -c hz -n "__fish_hz_using_subcommand restore" -s o -l output -d 'The destination folder the extraction was started with, if it was not the default one' -r -F
complete -c hz -n "__fish_hz_using_subcommand restore" -s q -l quiet -d 'Print only errors and prompts'
complete -c hz -n "__fish_hz_using_subcommand restore" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c hz -n "__fish_hz_using_subcommand restore" -s V -l version -d 'Print version'
complete -c hz -n "__fish_hz_using_subcommand completions" -s q -l quiet -d 'Print only errors and prompts'
complete -c hz -n "__fish_hz_using_subcommand completions" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c hz -n "__fish_hz_using_subcommand completions" -s V -l version -d 'Print version'
complete -c hz -n "__fish_hz_using_subcommand man" -s q -l quiet -d 'Print only errors and prompts'
complete -c hz -n "__fish_hz_using_subcommand man" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c hz -n "__fish_hz_using_subcommand man" -s V -l version -d 'Print version'
complete -c hz -n "__fish_hz_using_subcommand help; and not __fish_seen_subcommand_from extract check list test restore completions man help" -f -a "extract" -d 'Extract an archive, removing it progressively'
complete -c hz -n "__fish_hz_using_subcommand help; and not __fish_seen_subcommand_from extract check list test restore completions man help" -f -a "check" -d 'Show the space plan for an archive without modifying it'
complete -c hz -n "__fish_hz_using_subcommand help; and not __fish_seen_subcommand_from extract check list test restore completions man help" -f -a "list" -d 'List the entries of an archive'
complete -c hz -n "__fish_hz_using_subcommand help; and not __fish_seen_subcommand_from extract check list test restore completions man help" -f -a "test" -d 'Verify every entry of an archive without writing files'
complete -c hz -n "__fish_hz_using_subcommand help; and not __fish_seen_subcommand_from extract check list test restore completions man help" -f -a "restore" -d 'Restore a partially extracted archive to a standard archive'
complete -c hz -n "__fish_hz_using_subcommand help; and not __fish_seen_subcommand_from extract check list test restore completions man help" -f -a "completions" -d 'Print a shell completion script'
complete -c hz -n "__fish_hz_using_subcommand help; and not __fish_seen_subcommand_from extract check list test restore completions man help" -f -a "man" -d 'Print the man page (roff)'
complete -c hz -n "__fish_hz_using_subcommand help; and not __fish_seen_subcommand_from extract check list test restore completions man help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
