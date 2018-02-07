call plug#begin('~/.local/share/nvim/plugged')

Plug 'sheerun/vim-polyglot'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Themes
Plug 'chriskempson/base16-vim'

call plug#end()

map <C-n> :NERDTreeToggle<CR>

colorscheme base16-solarized-dark

let g:airline_theme='base16'

if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
  let &t_SI = "\<Esc>]50;CursorShape=1\x7"
  let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

" UI
set number " show line numbers
set showcmd " show command in bottom bar (maybe useless because of airline?)
set cursorline " highlight current line
set wildmenu " visual autocomplete for command menu
set lazyredraw " redraw only when we need to.
set showmatch " highlight matching [{()}]

" Search
set incsearch " search as characters are entered
set hlsearch " highlight matches

" Whitespaces
match Error /\s\+$/
match Error /^\t\+/

" airline configuration
let g:airline_powerline_fonts = 1
