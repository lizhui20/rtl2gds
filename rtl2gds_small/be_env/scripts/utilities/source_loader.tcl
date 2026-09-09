proc rm_source { args } {

  global env SEV synopsys_program_name search_path test_en

  set options(-file) ""
  set options(-quiet) 1
  set options(-optional) 0
  set options(-print) ""
  parse_proc_arguments -args $args options

  ## if { ![info exists SEV(config,verbosity)] } {
  ##   set SEV(config,verbosity) "lower"
  ## }

  if { [llength $options(-file)] > 0 } {

    set script_file_which [which $options(-file)]
    if { [llength $script_file_which] > 0 } {
      set script_file [file normalize $script_file_which]
      if { $script_file != [file normalize $options(-file)] } {
        puts "RM-info     : Found $options(-file) using search_path"
      }
    } else {
      set script_file $options(-file)
    }
 
    switch $synopsys_program_name {
      tcl -
      spyglass {
        set cmd_verbosity ""
      }
      default {
        if { $options(-quiet) } {
          set cmd_verbosity ""
        } else {
          set cmd_verbosity "-e"
        }
      }
    }

    set cmd_continue ""

    if { [file exists $script_file] } {

      set date [clock format [clock seconds] -format {%a %b %e %H:%M:%S %Y}]
      if {[info exists test_en] && $test_en == 1} {
          puts "RM-info    : SCRIPT_START : [file normalize $script_file] : $date"
          set cmd_verbosity "-e"
      } else {
          puts "RM-info    : SCRIPT_START : $options(-file) : $date"
      }
      set cmd "uplevel 1 source $cmd_verbosity $cmd_continue $script_file"
      eval $cmd

      set date [clock format [clock seconds] -format {%a %b %e %H:%M:%S %Y}]
      if {[info exists test_en] && $test_en == 1} {
          puts "RM-info    : SCRIPT_STOP : [file normalize $script_file] : $date"
          
      } else {
          puts "RM-info    : SCRIPT_STOP : $options(-file) : $date"
      }
      return 1

    } else {

      puts "RM-error   : rm_source: The specified file does not exist; '$options(-file)' : '$options(-print)'"
      return 0

    }
  } else {

    if {$options(-optional)} {
      puts "RM-info     : rm_source : Optional file corresponds to an empty variable. '$options(-print)'"
    } else {
      puts "RM-error    : rm_source : An empty file specification was provided; '$options(-print)'"
    }
    return 0
  }

}

define_proc_attributes rm_source \
  -info "Provides a standard way to source files. Returns a 0 if no file was sourced." \
  -define_args {
  {-file     "Used to specify the file to source." AString string required}
  {-optional "Allows an <empty-string> -file argument to output a message and not an error" "" boolean optional}
  {-print    "string to enhance default messages when file is <empty-string>." AString string optional}
  {-quiet "Echo minimal file content." "" boolean optional}
}
#set debug_path  ""
set search_path [concat "." $search_path ${debug_path}/scripts ${root_path}/scripts/fc_syn  \
                ${root_path}/scripts/fm ${root_path}/scripts/pt ${root_path}/scripts/utilities \
                ${run_path}/inputs ]
