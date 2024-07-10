<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');

include('../utils/db.php');

$isbn = $_GET['isbn'] ?? null;
$_SESSION['libro'] = $isbn;

function get_book()
{
  $isbn = $_SESSION['libro'];
  if (!$isbn) return;

  $sql = "
  SELECT * FROM libro l
  WHERE l.isbn = $1
  LIMIT 1
  ";

  $query_name = "book-$isbn";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($isbn));

  if (!$res) return;
  return pg_fetch_assoc($res);
}

function get_book_authors()
{
  $isbn = $_SESSION['libro'];
  if (!$isbn) return [];

  $sql = "
  SELECT s.autore FROM scrittura s
  WHERE s.libro = $1
  ";

  $query_name = "book-$isbn-authors";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($isbn));

  if (!$res) return [];

  $data = array();

  while ($row = pg_fetch_assoc($res))
    array_push($data, $row['autore']);

  return $data;
}

function get_all_publishers()
{
  $sql = "
  SELECT e.id, e.nome FROM casa_editrice e
  ORDER BY e.nome
  ";

  $query_name = "publishers";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array());

  if (!$res) return [];

  $data = array();

  while ($row = pg_fetch_assoc($res))
    array_push($data, $row);

  return $data;
}

function get_all_authors()
{
  $sql = "
  SELECT a.id, a.nome, a.cognome, a.pseudonimo FROM autore a
  ORDER BY a.pseudonimo, a.nome, a.cognome
  ";

  $query_name = "authors";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array());

  if (!$res) return [];

  $data = array();

  while ($row = pg_fetch_assoc($res))
    array_push($data, $row);

  return $data;
}
?>

<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Portale bibliotecari - MyBiblioteca</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous" />
  <link rel="stylesheet" href="../index.css" />
</head>

<body>
  <div>
    <?php include('../components/navbar.php') ?>

    <div class="center d-flex flex-column gap-4">
      <h1 style="margin-top: -56px;">
        <?php print $_SESSION['libro'] ? 'Modifica libro' : 'Crea un nuovo libro'; ?>
      </h1>
      <form method="post" action="<?php print $_SESSION['libro'] ? 'edit-book.php' : 'create-book.php'; ?>" class="d-flex flex-column gap-2 mb-4">
        <?php
        include('../utils/nome.php');

        $libro = get_book();
        $autoriLibro = get_book_authors();
        $authors = get_all_authors();
        $publishers = get_all_publishers();
        function get_v($k)
        {
          global $libro;
          if (!$libro) return;
          return $libro[$k];
        }

        print '<input type="text" id="isbn" name="isbn" class="form-control text-center" placeholder="il suo isbn" required minlength="10" maxlength="13" '.($_SESSION['libro'] ? 'disabled' : '').' value="' . get_v('isbn') . '" />';
        print '<input type="text" id="titolo" name="titolo" class="form-control text-center" placeholder="il suo titolo" required value="' . get_v('titolo') . '" />';
        print '<input type="date" title="pubblicazione" id="pubblicazione" name="pubblicazione" class="form-control text-center" placeholder="la sua data di pubblicazione" value="' . get_v('pubblicazione') . '" />';
        print '<input type="number" id="pagine" name="pagine" class="form-control text-center" placeholder="il numero di pagine" required value="' . get_v('pagine') . '" />';

        print '<select name="editore" title="editore" class="form-control text-center" required>';
        print '<option value="" disabled '.($_SESSION['libro'] ? '' : 'selected').'>Casa editrice</option>';
        foreach ($publishers as $publisher) {
          $selected = get_v('editore') == $publisher['id'] ? 'selected': '';
          print "<option $selected value=\"" . $publisher['id'] . '">' . $publisher['nome']. '</option>';
        }
        print '</select>';

        print '<select multiple name="autori[]" class="form-control text-center" required>';
        print '<option value="" disabled '.($_SESSION['libro'] ? '' : 'selected').'>Autori</option>';
        foreach ($authors as $author) {
          $selected = in_array($author['id'], $autoriLibro) ? 'selected': '';
          print "<option $selected value=\"" . $author['id'] . '">' . get_writer_name($author['pseudonimo'], $author['nome'], $author['cognome']). '</option>';
        }
        print '</select>';


        print '<textarea id="trama" name="trama" class="form-control" rows="5" placeholder="la sua trama" required>' . get_v('trama')  . '</textarea>';

        print '<button type="submit" class="btn btn-primary">' . ($_SESSION['libro'] ? 'Modifica' : 'Crea') . '</button>';
        ?>
      </form>

      <?php if ($_SESSION['libro']) print '<a href="./copie.php?isbn=' . $_SESSION['libro'] . '">Copie</a>'; ?>
    </div>
  </div>
</body>

</html>