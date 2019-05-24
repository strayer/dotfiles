;;; ~/.doom.d/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here

;; Make gpg-agent for SSH work in emacs
(setenv "SSH_AUTH_SOCK" (expand-file-name "~/.gnupg/S.gpg-agent.ssh"))

(setq doom-font (font-spec :family "Iosevka" :size 13))
(setq doom-big-font (font-spec :family "Iosevka" :size 28))

;; (setq doom-font (font-spec :family "Monoid" :style "Retina" :size 12))
;; (setq doom-big-font (font-spec :family "Monoid" :style "Retina" :size 28))

;; Maximize on start
(add-hook 'window-setup-hook #'toggle-frame-maximized)

;; Enable auto company completions
(setq company-idle-delay 0.2
  company-minimum-prefix-length 3)

  (defvar +evil--default-cursor-color "#ffffff")
  (defvar +evil--emacs-cursor-color "#ff9999")
  (defvar +evil--current-cursor-color nil)

  (defun +evil|update-cursor-color ()
    (setq +evil--default-cursor-color (face-background 'cursor)
          +evil--emacs-cursor-color (face-foreground 'warning)))
  (add-hook 'doom-load-theme-hook #'+evil|update-cursor-color)

  (defun +evil-default-cursor ()
    (unless (equal +evil--current-cursor-color +evil--default-cursor-color)
      (set-cursor-color +evil--default-cursor-color)
      (setq +evil--current-cursor-color +evil--default-cursor-color)))
  (defun +evil-emacs-cursor ()
    (unless (equal +evil--current-cursor-color +evil--emacs-cursor-color)
      (set-cursor-color +evil--emacs-cursor-color)
      (setq +evil--current-cursor-color +evil--emacs-cursor-color)))

;; Mac-specific settings
(when (eq system-type 'darwin)
  ;; Transparent titlebar
  ;; (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
  ;; (add-to-list 'default-frame-alist '(ns-appearance . dark))

  ;; Do not handle opt key (used to type Umlauts)
  ;;(setq mac-option-key-is-meta nil)
  ;;(setq mac-command-key-is-meta t)
  ;;(setq mac-command-modifier 'meta)
  ;;(setq mac-option-modifier nil)

  ;; Enable ligatures
  ;(mac-auto-operator-composition-mode)
  )
