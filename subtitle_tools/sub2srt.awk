#!/usr/bin/env gawk


# begin rule
BEGIN{
  # subtitle counter - init
  cnt=0;
  cnt=1;
  
  # rate factor
  if (rate=="")
    rate=25.0;
}


# @ line rule
{
  if( $0 ~ /(\{[0-9]+\})[ \t]*(\{[0-9]+\})[ \t]*(.*)/ )
  {
    # match
    match($0, /\{([0-9]+)\}[ \t]*\{([0-9]+)\}[ \t]*/, marr);
    match($0, /([ \t]*\{[0-9]+\}[ \t]*\{[0-9]+\}[ \t]*)/);
    sttl=substr($0,RLENGTH+1);
    printf ( "%d\n%s --> %s\n%s\n\n", cnt, 
                                   f_sec2srtime(0.0 + marr[1]/rate), 
                                   f_sec2srtime(0.0 + marr[2]/rate), 
                                   trim_spaces(sttl) );
    cnt++;
    
  }
}


# end rule
END{
  # no action
}


# eof



