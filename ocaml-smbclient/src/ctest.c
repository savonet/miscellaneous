/* $Id$ */

#include <libsmbclient.h>
#include <unistd.h>

void auth_fn (const char *srv, 
	      const char *shr,
	      char *wg, int wglen, 
	      char *un, int unlen,
	      char *pw, int pwlen) {
  printf ("wg '%s' un '%s' pw '%s'\n", wg, un, pw) ;
  strcpy (wg, "REZO") ;
  strcpy (pw, "") ;
  strcpy (un, "bob") ;
  printf ("wg '%s' un '%s' pw '%s'\n", wg, un, pw) ;
  return ;
}

char* url =  "smb://FOOTWAR/Mp3/u2/U2 - All That You Can't Leave Behind - 06 - In A Little Whil.mp3" ;


int main () {
  printf ("Bonjour!\n") ;

  if (smbc_init (auth_fn, 0)) {
    perror ("smbc_init") ;
  }

  int fd = smbc_open (url, O_RDONLY, 700) ;
  if (fd<0) {
    perror ("smbc_open") ;
  }

  /*  printf ("Reading ...\n") ;
  char byte[1024] ; int size ;
  while (0 < (size=smbc_read (fd, byte, 1024))) {
    write (STDERR_FILENO, byte, size) ;
  }
  if (size) perror ("smbc_read") ;
  */
  printf("Checking sizeof(off_t) for smimou: %d\n",sizeof(off_t));
  printf("Checking sizeof(long) for loulou: %d\n",sizeof(long));
  printf("File descriptor: %d.\n",fd);
  printf("Seeking 10 bytes with SEEK_SET\n");
  off_t x = 10LL;
  off_t res1 = smbc_lseek(fd, x, SEEK_SET);
  printf("Seeking 100 bytes with SEEK_CUR\n");
  off_t res2 = smbc_lseek(fd, 100LL, SEEK_CUR);
  printf("Seeking 0 bytes with SEEK_END\n");
  off_t res3 = smbc_lseek(fd, 0LL, SEEK_END);
  printf("First result: %lld\tSecond result: %lld\tThird result: %lld\n",
	 res1,res2,res3);

  if (smbc_close (fd)) {
    perror ("smbc_close") ;
  }

  printf ("Cassos!\n") ;
}
