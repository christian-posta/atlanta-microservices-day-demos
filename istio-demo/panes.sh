SOURCE_DIR=$PWD
tmux split-window -v -d -c $SOURCE_DIR
tmux select-pane -t 1
tmux split-window -h -d -c $SOURCE_DIR
tmux select-pane -t 0