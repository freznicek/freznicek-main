#/usr/bin/env awk -f

# begin rule
BEGIN{

  arr[-1]=0;

}

# at line rule
{
  for(i=1; i<=NF; i++)
  {
    found_indx=-1
    for(j=0; j<arr[-1]; j++)
    {
      if ($i == arr[j,0])
      {
        found_indx = j;
        break;
      }
    }
    # eval
    if (found_indx > -1)
    {
      # found
      arr[found_indx,1]++;
    } else
    {
      arr[arr[-1],0]=$i;
      arr[arr[-1],1]=1;
      arr[-1]++;
    }
  }
}


# end rule
END{
  for(j=0; j<arr[-1]; j++)
  {
    printf("%d %s\n", arr[j,1], arr[j,0]);
  }
}

# eof