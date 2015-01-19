<!-- Start with some composing HTML.. -->
<!DOCTYPE html>
<html>
  <body>
    <p>Hello world!</p>
    <a href="http://www.google.com/">A Link to Google!</a>
    <?php echo "PHP" ?> <!--some simple interpolated PHP -->
    <? echo 'Not good style' ?> <!--some simple interpolated PHP using only '<?' -->

    <!-- all right, time go through some PHP syntax -->
    <?php
      echo 'This is a test'; // This is a one-line c++ style comment
      /* This is a multi line comment
         yet another line of comment */
      echo 'This is yet another test';
      echo 'One Final Test'; # This is a one-line shell-style comment

    ?>
  </body>
</html>

<!-- PHP is parsed until end of block or EOF -->
<?php
// hasta el fin!
echo "This goes on and on until the end.."
