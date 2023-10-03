# Hello World (hello.janet)
# Asks your name, reads it, removes trailing newline, prints message
# Complexity: as low as humanly possible
# Usage: janet hello.janet

(defn main [&]
  (print "What is your name?")
  (def name
    (string/trim
     (file/read stdin :line)
     "\n"))
  (print "Hello " name " how are you?"))

# end hello.janet
