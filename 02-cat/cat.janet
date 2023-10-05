# GNU cat clone (cat.janet)
# A copy of the GNU program "cat" to print out file(s)
# Includes as many features from cat as possible
# Usage: janet cat.janet <option> ... <file> ...
# Complexity: eh, not the worst

# a made-up version number, why not
(def CAT-VERSION "cat (fun utils) 1.0\n
Copyright (C) 2023 null corporation\n
License MIT\n
This is free software; you are free to change and redistribute it\n
There is NO WARRANTY, to the extent permitted by law\n
\n
Written by Steven Leibrock\n")

(def CAT-HELP "cat - a drop-in replacement for GNU cat\n
Usage: cat [OPTION]... [FILE]...\n
Concatenate FILE(s) to standard output.\n
\n
  -A, --show-all         equivalent to -vET\n
  -b, --number-nonblank  number nonempty output lines, overrides -n\n
  -e                     equivalent to -vE\n
  -E, --show-ends        display $ at the end of each line\n
  -n, --number           number all output lines\n
  -s, --squeeze-blank    suppress repeated empty output lines\n
  -t                     equivalent to -vT\n
  -T, --show-tabs        display TAB characters as ^I\n
  -u                     (ignored)\n
  -v, --show-nonprinting use ^ and M- notation, except for LFD and TAB\n
  --help                 display help and exit\n
  --version              display version info and exit\n
\n
Examples:\n
  cat f - g   Output f's contents, then standard input, then g's\n
  cat         Copy standard input to standard output\n
\n
MIT licensed, enjoy.")

# A mutable settings table
(defn Make-Settings []
  @{:squeeze false  # compress empty line output
    :number  false  # number all lines at the start
    :numberb false  # number all lines, EXCEPT blank
    :ends    false  # output a $ at line end
    :tabs    false  # print tabs as ^T
    :vmode   false  # print non-ASCII characters in ^/M- notation
    :version false  # print the version and quit
    :help    false  # print help and quit
    :stop    false  # stops option reading
   })

# A table of keycodes to match to a function to mutate our settings
# should try to mirror GNU cat's options as much as possible
(def short-options
  {118 (fn [S] (set (S :vmode) true))
   117 (fn [S] nil)
    98 (fn [S] (set (S :number) true))
   101 (fn [S] (set (S :ends) true))
   115 (fn [S] (set (S :squeeze) true))
   116 (fn [S] (set (S :tabs) true))
   })

# Keycodes that match up to the shortcodes, but more verbose
# Done for compatibility-sake
(def long-options
  {"--show-ends"        (fn [S] (set (S :ends) true))
   "--number-nonblank"  (fn [S] (set (S :numberb) true))
   "--squeeze-blank"    (fn [S] (set (S :squeeze) true))
   "--show-tabs"        (fn [S] (set (S :tabs) true))
   "--show-nonprinting" (fn [S] (set (S :vmode) true))
   "--help"             (fn [S] (set (S :help) true))
   "--version"          (fn [S] (set (S :version) true))
   "--"                 (fn [S] (set (S :stop) true))
   "--show-all" (fn [S]
                  (do
                    (set (S :ends) true)
                    (set (S :tabs) true)
                    (set (S :vmode) true)
                    (print "Hey")))
  })

# Is a string a short or long option?
(defn option? [string]
  (and (not (= "-" string))
       (or (string/has-prefix? "--" string)
           (string/has-prefix? "-" string))))

# Print character function
(defn print-char [char show-tab show-nonascii]
  (prinf "%c" char))

(defn print-nl [show-end show-numbered number-nonb]
  (if (= show-end true)
    (print "$")
    (print "")))

# This is the main logic for the cat program
# It takes a file path for reading, and a Settings table
(defn CAT [file settings]
  (var newline-counter 0)
  (def stat (or (= :core/file (type file))
                (os/stat file)))
  (def squeeze-newlines (get settings :squeeze))
  (def show-newlines    (get settings :ends))
  (def show-tabs        (get settings :tabs))
  (def show-nonascii    (get settings :vmode))
  (def show-numbered    (get settings :number))
  (def numbered-nonb    (get settings :numberb))

  (if (= stat nil)
    (do
      (print "File '" file "' cannot be found")
      (os/exit 2))
    (do
      (def fi (if (= :core/file (type file))
                file
                (file/open file)))
      (while (def line (file/read fi :line))
        (each char line
          (if (= char 10)
            (do
              (set newline-counter (+ newline-counter 1))
              (unless (and squeeze-newlines (> newline-counter 2))
                (print-nl show-newlines show-numbered numbered-nonb)))
            (do
              (set newline-counter 0)
              (print-char char show-tabs show-nonascii)))))
      (file/close fi))))

# Main entrypoint
(defn main [& args]
  (def Settings (Make-Settings))
  (var idx 0)
  (def files @[])

  (for i 1 (length args)
    (def arg (get args i))

    (if (option? arg)
      (when (not (get Settings :stop))
        (cond
          (string/has-prefix? "--" arg)
          (if (has-key? long-options arg)
            ((get long-options arg) Settings)
            (do
              (print "cat: unrecognized option '" arg "'")
              (print "Try 'cat --help' for more information.")
              (os/exit 1)))
          (string/has-prefix? "-" arg)
          (each char arg
            (when (not (= char 45))
              (if (has-key? short-options char)
                ((get short-options char) Settings)
                (do
                  (printf "cat: invalid option -- '%c'" char)
                  (print "Try 'cat --help' for more information.")
                  (os/exit 1)))))))
      (do
        (if (= arg "-")
          (set (files idx) stdin)
          (set (files idx) arg))
        (set idx (+ idx 1)))))

  (when (get Settings :version)
    (print CAT-VERSION)
    (os/exit 0))

  (when (get Settings :help)
    (print CAT-HELP)
    (os/exit 0))

  (each file files
    (CAT file Settings)))



# end cat.janet
