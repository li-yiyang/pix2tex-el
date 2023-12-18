;;; pix2tex-el --- Emacs with pix2tex -*- lexical-binding: t -*-

;;; Commentary:

;;; Code:
(require 'epc)

;; Hooks
(defvar pix2tex-el-insert-hook nil
  "Hook that triggered after the formula is inserted.")

;; Screencapture
(defvar pix2tex-el-screencapture-command
  (cond ((eq system-type 'darwin) "screencapture"))
  "Program used to capture screencapture.")

(defun pix2tex-el-screencapture (&rest args)
  "Take a screencapture."
  (shell-command
   (combine-and-quote-strings
    (cons pix2tex-el-screencapture-command args))))

;; I think using clipboard may not be a good idea,
;; maybe in the future version to add temp file function.
(defun pix2tex-el--screencapture-to-clipboard ()
  "Take a screencapture interactively and save it into clipboard."
  (pix2tex-el-screencapture "-i" "-c"))

;; PIX2TEX Server
(defvar pix2tex-el-py-path
  (expand-file-name "pix2tex-el.py"
                    (file-name-directory
                     (or load-file-name buffer-file-name)))
  "Path to pix2tex-el.py.")

(defvar pix2tex-el-server-process nil
  "Server running pix2tex backend.")

(defvar pix2tex-el-ocr-stack nil
  "Stack holding pix2tex ocr results.")

(defun pix2tex-el--quit-process ()
  "Quit pix2tex server process."
  (epc:stop-epc pix2tex-el-server-process))

(defun pix2tex-el--start-process ()
  "Start pix2tex server process."
  (when (epc:live-p pix2tex-el-server-process)
    (epc:stop-epc pix2tex-el-server-process))
  (setf pix2tex-el-server-process
        (epc:start-epc (or (getenv "PYTHON")
                           (cond ((executable-find "python3") "python3")
                                 ((executable-find "python") "python")
                                 (t "python")))
                       (list pix2tex-el-py-path)))
  (message "PIX2TEX Server Started"))

(defun pix2tex-el--ensure-process ()
  "Ensure `pix2tex-el-server-process' is living."
  (unless (epc:live-p pix2tex-el-server-process)
    (pix2tex-el--start-process)))

;; this function is not used yet...
(defun pix2tex-el-ocr-clipboard ()
  "Interactively OCR screen into clipboard and OCR it."
  (pix2tex-el--screencapture-to-clipboard)
  (pix2tex-el--ensure-process)
  (epc:call-sync pix2tex-el-server-process 'clipboard nil))

;; it's now async, but may not be so flexible
(defun pix2tex-el-insert ()
  "Take screencapture and insert it at point."
  (interactive)
  (pix2tex-el--screencapture-to-clipboard)
  (pix2tex-el--ensure-process)
  (let ((insert-position (point)))
    (deferred:$
     (epc:call-deferred pix2tex-el-server-process 'clipboard nil)
     (deferred:nextc it `(lambda (latex)
                           (save-excursion
                             ;; NOTE: This is hacky! need improving...
                             (goto-char ,insert-position)
                             (insert-before-markers (format "\\(%s\\)" latex))
                             (run-hooks 'pix2tex-el-insert-hook)))))))

(provide 'pix2tex-el)
;;; pix2tex-el.el ends here
