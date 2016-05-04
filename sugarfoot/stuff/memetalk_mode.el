(defvar memetalk-mode-hook nil)

; "If your keymap will have very few entries, then you may want to consider
; ‘make-sparse-keymap’ rather than ‘make-keymap’."
(defvar memetalk-mode-map
  (let ((map (make-keymap)))
    (define-key map "\M-e" 'memetalk-do-it)
    (define-key map "\M-p" 'memetalk-print-it)
    (define-key map "\C-i" 'memetalk-step-into)
    (define-key map "\C-o" 'memetalk-step-over)
    (define-key map "\C-u" 'memetalk-step-out)
    (define-key map "\C-l" 'memetalk-step-line)
    map)
  "Keymap for memetalk major mode")


(add-to-list 'auto-mode-alist '("\\.mm\\'" . memetalk-mode))


(setq memetalk-keywords '("preamble" "code" "endcode" "class" "fields"
                          "init" "fun" "super" "instance_method" "class_method"
                          "if" "else" "try" "end" "catch" "var" "primitive" "return"))

(setq memetalk-constants '("true" "false" "null"))

(setq memetalk-keywords-regexp (regexp-opt memetalk-keywords 'words))
(setq memetalk-constants-regexp (regexp-opt memetalk-constants 'words))

;; font-lock-defaults
;; js--font-lock-keywords-3 js--font-lock-keywords-1 js--font-lock-keywords-2 js--font-lock-keywords-3))

;;TODO:
;; @vars
;; this
;; thisModule
;; thisContext

(defconst memetalk-font-lock-keywords
  (list
   `(,memetalk-keywords-regexp . font-lock-keyword-face)
   `(,memetalk-constants-regexp . font-lock-constant-face)
   '("^\\s-*instance_method\\s-+\\([a-zA-Z_$]\\(?:\\s_\\|\\sw\\)*\\)" 1 font-lock-variable-name-face)
   '("^\\([a-zA-Z_$]\\(?:\\s_\\|\\sw\\)*\\):" 1 font-lock-function-name-face)
   '("var\\s-+\\([a-zA-Z_$]\\(?:\\s_\\|\\sw\\)*\\)" 1 font-lock-variable-name-face)
  "Highlighting expressions for memetalk mode"))

;; I believe the following is for c++ style comments
(defvar memetalk-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?_ "w" st)
    (modify-syntax-entry ?/ ". 124b" st)
    (modify-syntax-entry ?* ". 23" st)
    (modify-syntax-entry ?\n "> b" st)
    st)
  "Syntax table for memetalk-mode")

(defun memetalk-mode ()
  "Major mode for editing Workflow Process Description Language files"
  (interactive)
  (kill-all-local-variables)
  (set-syntax-table memetalk-mode-syntax-table)
  (use-local-map memetalk-mode-map)
  (set (make-local-variable 'font-lock-defaults) '(memetalk-font-lock-keywords))
  ;; (set (make-local-variable 'indent-line-function) 'memetalk-indent-line)
  (setq major-mode 'memetalk-mode)
  (setq mode-name "memetalk")
  (run-hooks 'memetalk-mode-hook))

;; utils

(defun memetalk-trim-r (string)
  (when (string-match "[ \t\n]*$" string)
    (replace-match "" nil nil string)))

(defun memetalk-module-name-from-path (filepath)
  (file-name-nondirectory (file-name-sans-extension filepath)))

;; socket

(defvar memetalk-repl-recon-timer nil)

(defun memetalk-repl-setup-reconnection ()
  (unless memetalk-repl-recon-timer
    (setq memetalk-repl-recon-timer (run-at-time "1 second" 1 'memetalk-repl-connect))))

(defun memetalk-repl-detect-disconnect (process event)
  (message (format "%s %s" process (memetalk-trim-r event)))
  (memetalk-remove-overlays memetalk-current-buffer)
  (memetalk-repl-setup-reconnection))


(defun memetalk-repl-is-open ()
  (and (process-status "mm-repl") t))

;; (defun memetalk-repl-last-response ()
;;   (if (memetalk-repl-is-open)
;;       (with-current-buffer "*mm-repl*"
;;         (memetalk-trim-r (thing-at-point 'line)))
;;     nil))

(defun memetalk-repl-send (cmd)
  (if (memetalk-repl-is-open)
      (process-send-string "*mm-repl*" (concat cmd "\0"))
    nil))


;; repl high level commands
(defun memetalk-repl-load (module-name)
  (memetalk-repl-send (concat "load " module-name)))

(defun memetalk-repl-do-it (code)
  (memetalk-repl-send (concat "do-it " (base64-encode-string code))))

(defun memetalk-repl-print-it (code)
  (memetalk-repl-send (concat "print-it " (base64-encode-string code))))


(defvar memetalk-current-module-filepath nil)

;;; operations

(defun memetalk-repl-connect ()
  (interactive)
  (setq mm-repl-socket nil)
  (condition-case nil
      (progn
        (setq mm-repl-socket (open-network-stream "mm-repl"
                                                  "*mm-repl*" "localhost" 4200))
        (message "memetalk repl connected")
        (set-process-sentinel mm-repl-socket 'memetalk-repl-detect-disconnect)
        (cancel-timer memetalk-repl-recon-timer)
        (setq memetalk-repl-recon-timer nil))
        ;; (if memetalk-current-module-filepath
        ;;     (memetalk-instantiate-module memetalk-current-module-filepath)))
    (error nil))
  mm-repl-socket)

(defun memetalk-work-on-current-module ()
  (interactive)
  (memetalk-instantiate-module (buffer-file-name)))

(defun memetalk-do-it ()
  (interactive)
  (let ((code (memetalk-current-selection)))
    (memetalk-repl-do-it code)))

(defun memetalk-print-it ()
  (interactive)
  (let ((code (memetalk-current-selection)))
    (memetalk-repl-print-it code)))

(defun memetalk-step-into ()
  (interactive)
  (memetalk-repl-send "step-into"))

(defun memetalk-step-over ()
  (interactive)
  (memetalk-repl-send "step-over"))

(defun memetalk-step-line ()
  (interactive)
  (memetalk-repl-send "step-line"))

(defun memetalk-step-out ()
  (interactive)
  (memetalk-repl-send "step-out"))


;; utils
(defun memetalk-current-selection ()
  (condition-case nil
      (with-current-buffer (current-buffer)
        (buffer-substring-no-properties (mark) (point)))))

(defun memetalk-instantiate-module (filepath)
  (setq memetalk-current-module-filepath filepath)
  (if (memetalk-repl-is-open)
      (let ((module-name (memetalk-module-name-from-path filepath)))
        (memetalk-repl-load module-name))))

;; hooks

(defun memetalk-after-save ()
  (if (equal (buffer-file-name) memetalk-current-module-filepath)
      (progn
        (memetalk-instantiate-module memetalk-current-module-filepath))))


(defvar memetalk-response-content "")
;; (message memetalk-response-content)
;; (setq memetalk-response-content "")


(defvar memetalk-current-buffer nil)
(defun change-memetalk-current-buffer (buffer)
  (if memetalk-current-buffer
      (memetalk-remove-overlays memetalk-current-buffer))
  (setq memetalk-current-buffer buffer))

(defvar memetalk-path (or  (getenv "MEME_PATH") "/Users/jester/src/memetalk/sugarfoot/mm/"))

(defvar commands (list))
(defun memetalk-repl-dispatch-response (resp)
  (message (format "received response '%s'" resp))
  (setq commands (cons resp commands))
  (if (equal (string-match "module: \\(.*\\)@" resp) 0)
      (let ((file-part (match-string-no-properties 1 resp)))
        (string-match "\\([a-zA-Z0-9]+\\)[:/]" file-part)
        (let ((mod-name (concat (match-string-no-properties 1 file-part) ".mm")))
          (message (format "mattched module '%s'" mod-name))
          (let ((mod-path (concat (file-name-as-directory memetalk-path) mod-name)))
            (with-current-buffer (find-file mod-path)
              (message (format "opened file '%s'" mod-path))
              (widen) ;this shit keep being opened narrowed, god damn it!
              (change-memetalk-current-buffer (current-buffer))))
          (message resp)
          (string-match
           "@\\[\\([0-9]+\\), \\([0-9]+\\), \\([0-9]+\\), \\([0-9]+\\)\\]"
           resp)
          (let ((start-line (string-to-number (match-string-no-properties 1 resp)))
                (start-col (string-to-number (match-string-no-properties 2 resp)))
                (end-line (string-to-number (match-string-no-properties 3 resp)))
                (end-col (string-to-number (match-string-no-properties 4 resp))))
            (with-current-buffer memetalk-current-buffer
              (memetalk-remove-overlays memetalk-current-buffer)
              (goto-line  (+ 1 start-line))
              (forward-char start-col)
              (let ((begin (point)))
                (goto-line (+ 1 end-line))
                (forward-char end-col)
                (let ((x (make-overlay begin (point))))
                  (overlay-put x 'face '(:box "yellow")))))))))
  (if (equal (string-match "show: \\(.*\\)" resp) 0)
      (with-current-buffer memetalk-current-buffer
        (let ((b64text (match-string-no-properties 1 resp))
              (cur-pos (point)))
          (deactivate-mark)
          (set-mark-command nil)
          (insert (base64-decode-string b64text))))))




(defun memetalk-repl-change (begin end x)
  (if (equal (buffer-name) "*mm-repl*")
      (progn
        (let ((content (buffer-substring-no-properties begin end)))
          (setq memetalk-response-content
                (concat memetalk-response-content content))
          (if (equal (string-match ".*\n" memetalk-response-content) 0)
              (progn
              (memetalk-repl-dispatch-response
               (memetalk-trim-r memetalk-response-content))
              (setq memetalk-response-content ""))))))
  t)

;; (remove-hook 'after-change-functions 'memetalk-after-change)
;; (add-hook 'after-change-functions 'memetalk-after-change)

(add-hook
 'after-change-functions 'memetalk-repl-change)

(provide 'memetalk-mode)

(defun memetalk-remove-overlays (buffer)
  (with-current-buffer buffer
    (remove-overlays (point-min) (point-max))))

(defun memetalk-get-last-procedure ()
  (interactive)
  (with-current-buffer (current-buffer)
    (condition-case nil
        (save-excursion
          (re-search-backward
           "^\\s-*\\(init\\s-+\\|instance_method\\s-+\\|class_method\\s-+\\|\\)\\(\\w+\\): fun")
          (let ((fname (match-string-no-properties 2))
                (ftype (match-string-no-properties 1))
                (begin (match-beginning 0)))
            (goto-char begin)
            (search-forward "{")
            (backward-char)
            (forward-sexp)
            (let ((x (make-overlay begin (point))))
              (overlay-put x 'face '(:box "yellow"))
              (run-at-time "0.2 second" nil
                           #'memetalk-remove-overlays (current-buffer)))))
      (error (message "No procedure before point :(")))))