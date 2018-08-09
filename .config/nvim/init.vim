call plug#begin('~/.local/share/nvim/plugged')

Plug 'sheerun/vim-polyglot'
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-surround'
Plug 'hashivim/vim-terraform'

Plug 'airblade/vim-gitgutter'

Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'

Plug 'equal-l2/vim-base64'

" Themes
" Plug 'chriskempson/base16-vim'
Plug 'morhetz/gruvbox'

call plug#end()

map <C-n> :NERDTreeFocus<CR>
map <S-n> :NERDTreeToggle<CR>

" colorscheme base16-solarized-dark
colorscheme gruvbox
set background=dark

let g:airline_theme='base16'
let g:deoplete#enable_at_startup = 1

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

" fzf
let $FZF_DEFAULT_COMMAND = 'ag --hidden --ignore .git -g ""'

" Whitespaces
match Error /\s\+$/
match Error /^\t\+/

" Indentation configuration
set tabstop=2 shiftwidth=2 expandtab

" airline configuration
let g:airline_powerline_fonts = 1

let g:terraform_fmt_on_save = 1

" <TAB> to navigate autocomplete popups
"inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
