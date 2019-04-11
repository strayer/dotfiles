;;; ~/.doom.d/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here

;; Make gpg-agent for SSH work in emacs
;;(set-env! "SSH_AUTH_SOCK")

(setq doom-font (font-spec :family "Iosevka" :size 13))
(setq doom-bg-font (font-spec :family "Iosevka" :size 28))
;
; Use GNU ls to offer more options to dired
(let ((gls-path "/usr/local/bin/gls"))
  (if (file-exists-p gls-path)
      (setq insert-directory-program gls-path)))

; Elixir formatting
(add-hook 'elixir-mode-hook #'+format|enable-on-save)

;; Maximize on start
(add-hook 'window-setup-hook #'toggle-frame-maximized)

;; Enable auto company completions
(setq company-idle-delay 0.2
  company-minimum-prefix-length 3)

;; Mac-specific settings
(when (eq system-type 'darwin)
  ;; Transparent titlebar
  ;; (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
  ;; (add-to-list 'default-frame-alist '(ns-appearance . dark))

  ;; Do not handle opt key (used to type Umlauts)
  ;;(setq mac-option-key-is-meta nil)
  ;;(setq mac-command-key-is-meta t)
  ;;(setq mac-command-modifier 'meta)
  (setq mac-option-modifier nil)

  ;; Enable ligatures
  ;(mac-auto-operator-composition-mode)
  )
