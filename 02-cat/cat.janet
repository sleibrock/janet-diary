# GNU cat clone (cat.janet)
# A copy of the GNU program "cat" to print out file(s)
# Includes as many features from cat as possible
# Usage: janet cat.janet <option> ... <file> ...

# a made-up version number, why not
(def CAT-VERSION "1.0")

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
  {"v" (fn [S] (set (S :vmode) true))
   "u" (fn [S] nil)
   "b" (fn [S] (set (S :number) true))
   "e" (fn [S] (set (S :ends) true))
   "s" (fn [S] (set (S :squeeze) true))
   "t" (fn [S] (set (S :tabs) true))
   })

# Keycodes that match up to the shortcodes, but more verbose
# Done for compatibility-sake
(def long-options
  {"--show-all" (fn [S] nil)
   "--show-ends" (fn [S] nil)
   "--number-nonblank" (fn [S] nil)
   "--squeeze-blank" (fn [S] nil)
   "--show-tabs" (fn [S] nil)
   "--show-nonprinting" (fn [S] nil)
   "--help" (fn [S] nil)
   "--version" (fn [S] nil)
   "--" (fn [S] (do (print "Stopping") (set (S :stop) true)))
  })


# Printable character function
(defn printable? [code]
  true)

# This is the main logic for the cat program
# It takes a file path for reading, and a Settings table
(defn CAT [file settings]
  (each line (file/lines file)
    (print line)))


(defn main [& args]
  (def Settings (Make-Settings))
  (def files @[])
  (print "Cat'ing a file lol")
  (for i 1 (length args)
    (def arg (get args i))
    (print "Arg " i " -> " arg)

    (when (not (get Settings :stop))
      (cond
        (string/has-prefix? "--" arg)
        (if (has-key? long-options arg)
          ((get long-options arg) Settings)
          (do
            (print "No option match")
            (quit 1)))
        (string/has-prefix? "-" arg)
        (if (has-key? short-options arg)
          ((get short-options arg) Settings)
          (do
            (print "Invalid option")
            (quit 1)))))
    
    (print "End cycle")
    )
  (print "Done")
  )


# end cat.janet
