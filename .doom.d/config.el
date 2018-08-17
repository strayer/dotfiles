;;; ~/.doom.d/config.el -*- lexical-binding: t; -*-

;; Make gpg-agent for SSH work in emacs
(set-env! "SSH_AUTH_SOCK")

(setq doom-font (font-spec :family "Iosevka" :size 13))

; Use GNU ls to offer more options to dired
(let ((gls-path "/usr/local/bin/gls"))
    (if (file-exists-p gls-path)
        (setq insert-directory-program gls-path)))

;; Mac-specific settings
(when (eq system-type 'darwin)
    ;; Transparent titlebar
    (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
    (add-to-list 'default-frame-alist '(ns-appearance . dark))

    ;; Do not handle opt key (used to type Umlauts)
    (setq mac-option-modifier nil)
)
