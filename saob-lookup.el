;;; saob-lookup --- View definition of swedish words -*- lexical-binding t; -*-
;;
;;; Copyright (c) 2021 Mikael Svahnberg
;;
;;; License:
;; The MIT License (MIT)
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.
;;
;;; Commentary:
;;
;; SETUP
;; 0. clone this repo into your load-path
;; 1. M-x saob-lookup

;;; Code:

(defgroup saob-lookup nil "saob-lookup variables")

(defcustom saob-lookup-saol "tri/f_saol.php?sok="
  "Base URL for ordlista"
  :type 'string
  :group 'saob-lookup)

(defcustom saob-lookup-saob "tri/f_saob.php?sok="
  "Base URL for ordbok"
  :type 'string
  :group 'saob-lookup)

(defcustom saob-lookup-so "tri/f_so.php?sok="
  "Base URL for Svensk Ordbok"
  :type 'string
  :group 'saob-lookup)

(defcustom saob-lookup-root-url "https://svenska.se/"
  "Base URL for swedish academy wordlists"
  :type 'string
  :group 'saob-lookup)


;;;###autoload
(defun saob-lookup (&optional word list)
  "Look up Swedish WORD in Swedish Academy Ordbok and/or Ordlista.
LIST is either of saob-lookup-saol ,saob-lookup-saob, or saob-lookup-so."
  (interactive (list (or (thing-at-point 'word)
                         (read-string "Word to search for: " nil 'saob-history))))
  (let* ((url (format "%s%s%s" saob-lookup-root-url (or list saob-lookup-saol) word)))
    (message "saob-lookup looking for word: %s" word)
      (when word (saob-lookup-follow-url url))))

(defun saob-lookup-render-page (status)
  "Cleanup and render the current buffer. STATUS is the http response."
  (let* ((buffer (get-buffer-create "*SAOB lookup*"))
         (response (buffer-string)) ;; Called from within url-retrieve so current-buffer is the raw HTTP response
         (raw-page (with-temp-buffer
                     (insert response)
                     (goto-char (point-min))
                     (re-search-forward "^$")
                     (delete-region (point) (point-min))
                     (decode-coding-region (point-min) (point-max) 'utf-8)
                     (buffer-string)))
         (rendered-page (with-temp-buffer
                          (insert raw-page)
                          (shr-render-region (point-min) (point-max))
                          (buffer-string))))
      (set-buffer buffer)
      (read-only-mode 0)
      (erase-buffer)
      (insert rendered-page)
      (goto-char (point-min))
      (saob-lookup-mode)
      (pop-to-buffer buffer)
      (concat "<EOP>")))

(defun saob-lookup-follow-url (url)
  "Retrieve and render URL."
  (message "saob-lookup following url: %s" url)
  (save-excursion
    (let ((url-mime-language-string "se, en")
          (url-mime-charset-string "utf-8"))
      (url-retrieve url 'saob-lookup-render-page))))

(defun saob-lookup-follow-link-at-point ()
  "Get link at point and retreive."
  (interactive)
  (message "Following link on page")
  (let ((url (shr-url-at-point nil)))
    (message "%s" url)
    (when url
      (saob-lookup-follow-url (format "%s%s" saob-lookup-root-url url)))))


;; A tiny major mode
;; --------------------

;;;###autoload
(define-derived-mode saob-lookup-mode special-mode "saob-lookup"
  "Major mode for viewing swedish word definitions."
  :group 'saob-lookup)

(define-key saob-lookup-mode-map (kbd "<return>") 'saob-lookup-follow-link-at-point)

;;; provides:
(provide 'saob-lookup)

;;; saob-lookup ends here

