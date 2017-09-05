" Plug
call plug#begin('~/.vim/plugged')

Plug 'morhetz/gruvbox'

"Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }

"Plug 'vim-ruby/vim-ruby', { 'for': 'ruby' }

"Plug 'maksimr/vim-jsbeautify'

"Plug 'jparise/vim-graphql'

Plug 'vim-airline/vim-airline'

Plug 'chr4/nginx.vim'

" Initialize plugin system
call plug#end()

" Never forget
" https://dougblack.io/words/a-good-vimrc.html

map <C-n> :NERDTreeToggle<CR>

syntax enable
colorscheme gruvbox

if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
  let &t_SI = "\<Esc>]50;CursorShape=1\x7"
  let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

set backspace=indent,eol,start

" reconfigure <leader> to ,
let mapleader = ","

" Allow modelines
set modeline
set modelines=5

" Spaces & Tabs
set tabstop=4     " number of visual spaces per TAB
set softtabstop=4 " number of spaces in tab when editing
set expandtab     " tabs are spaces


" UI
set number " show line numbers
set showcmd " show command in bottom bar (maybe useless because of airline?)
"set cursorline " highlight current line
set wildmenu " visual autocomplete for command menu
set lazyredraw " redraw only when we need to.
set showmatch " highlight matching [{()}]


" Search
set incsearch " search as characters are entered
set hlsearch " highlight matches

" turn off search highlight
nnoremap <leader><space> :nohlsearch<CR>

" Movement
" move vertically by visual line
nnoremap j gj
nnoremap k gk

" highlight last inserted text
nnoremap gV `[v`]

" Whitespaces
match Error /\s\+$/
match Error /^\t\+/

" Indentation
filetype indent on " load filetype-specific indent files

" make splits open below/right
set splitbelow
set splitright
