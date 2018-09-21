;;; ~/.doom.d/config.el -*- lexical-binding: t; -*-

;; Make gpg-agent for SSH work in emacs
(set-env! "SSH_AUTH_SOCK")

(setq doom-font (font-spec :family "Iosevka" :size 13))
(setq doom-bg-font (font-spec :family "Iosevka" :size 28))

;; Fonts
;;(setq doom-font (font-spec :family "Hack" :size 13))
;; On my (almost) 1440p monitor, 28pt Hack gives me about 30 lines and maybe
;; 100-120 columns, which seems like a good zoomed in size for eye
;; strain/showing other people stuff
;;(setq doom-big-font (font-spec :family "Hack" :size 28))

;(setq doom-theme 'doom-tomorrow-day)

; Use GNU ls to offer more options to dired
(let ((gls-path "/usr/local/bin/gls"))
  (if (file-exists-p gls-path)
      (setq insert-directory-program gls-path)))

; Elixir formatting
(add-hook 'elixir-mode-hook #'+format|enable-on-save)

(setq +email-backend 'nil)
(setq mu4e-maildir "~/Mail")

(set-irc-server! "chat.freenode.net"
                 `(:tls t
                        :port (6697 . 6697)
                        :nick "strayer"
                        :channels ("#emacs")))

;; Maximize on start
(add-hook 'window-setup-hook #'toggle-frame-maximized)

;; Temporary elixir-mode formatting fix for floats
(after! highlight-numbers
  (setq highlight-numbers-generic-regexp "\\_<[[:digit:]]+\\(?:\\.[0-9]*\\)?\\_>"))

;; Mac-specific settings
(when (eq system-type 'darwin)
  ;; Transparent titlebar
  (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
  (add-to-list 'default-frame-alist '(ns-appearance . dark))

  ;; Do not handle opt key (used to type Umlauts)
  (setq mac-option-modifier nil)

  ;; Enable ligatures
  ;(mac-auto-operator-composition-mode)
  )
