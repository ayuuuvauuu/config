# codex-zen completions
# Forward all codex subcommands + add --stop

complete -c codex-zen -f

# codex-zen --stop
complete -c codex-zen -l stop -d "Stop shared infra (relay + proxy)"

# codex-zen forwards everything else to codex, so complete with codex subcommands
complete -c codex-zen -n "not __fish_seen_subcommand_from exec review login logout mcp plugin mcp-server app-server remote-control completion update doctor sandbox debug apply resume archive delete unarchive fork" -xa "exec\td\"Run Codex non-interactively\""
complete -c codex-zen -n "not __fish_seen_subcommand_from exec review login logout mcp plugin mcp-server app-server remote-control completion update doctor sandbox debug apply resume archive delete unarchive fork" -xa "review\td\"Run a code review\""
complete -c codex-zen -n "not __fish_seen_subcommand_from exec review login logout mcp plugin mcp-server app-server remote-control completion update doctor sandbox debug apply resume archive delete unarchive fork" -xa "login\td\"Manage login\""
complete -c codex-zen -n "not __fish_seen_subcommand_from exec review login logout mcp plugin mcp-server app-server remote-control completion update doctor sandbox debug apply resume archive delete unarchive fork" -xa "logout\td\"Remove stored auth\""
complete -c codex-zen -n "not __fish_seen_subcommand_from exec review login logout mcp plugin mcp-server app-server remote-control completion update doctor sandbox debug apply resume archive delete unarchive fork" -xa "update\td\"Update Codex\""
complete -c codex-zen -n "not __fish_seen_subcommand_from exec review login logout mcp plugin mcp-server app-server remote-control completion update doctor sandbox debug apply resume archive delete unarchive fork" -xa "doctor\td\"Diagnose installation\""
complete -c codex-zen -n "not __fish_seen_subcommand_from exec review login logout mcp plugin mcp-server app-server remote-control completion update doctor sandbox debug apply resume archive delete unarchive fork" -xa "apply\td\"Apply latest diff\""
complete -c codex-zen -n "not __fish_seen_subcommand_from exec review login logout mcp plugin mcp-server app-server remote-control completion update doctor sandbox debug apply resume archive delete unarchive fork" -xa "resume\td\"Resume session\""
complete -c codex-zen -n "not __fish_seen_subcommand_from exec review login logout mcp plugin mcp-server app-server remote-control completion update doctor sandbox debug apply resume archive delete unarchive fork" -xa "archive\td\"Archive session\""
complete -c codex-zen -n "not __fish_seen_subcommand_from exec review login logout mcp plugin mcp-server app-server remote-control completion update doctor sandbox debug apply resume archive delete unarchive fork" -xa "delete\td\"Delete session\""
complete -c codex-zen -n "not __fish_seen_subcommand_from exec review login logout mcp plugin mcp-server app-server remote-control completion update doctor sandbox debug apply resume archive delete unarchive fork" -xa "fork\td\"Fork session\""
complete -c codex-zen -n "not __fish_seen_subcommand_from exec review login logout mcp plugin mcp-server app-server remote-control completion update doctor sandbox debug apply resume archive delete unarchive fork" -xa "sandbox\td\"Run in sandbox\""
complete -c codex-zen -n "not __fish_seen_subcommand_from exec review login logout mcp plugin mcp-server app-server remote-control completion update doctor sandbox debug apply resume archive delete unarchive fork" -xa "completion\td\"Generate completions\""
complete -c codex-zen -n "not __fish_seen_subcommand_from exec review login logout mcp plugin mcp-server app-server remote-control completion update doctor sandbox debug apply resume archive delete unarchive fork" -xa "debug\td\"Debugging tools\""
