<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
<script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/dist/umd/popper.min.js" integrity="sha384-I7E8VVD/ismYTF4hNIPjVp/Zjvgyol6VFvRkX/vR+Vc4jQkC+hVqc2pM8ODewa9r" crossorigin="anonymous"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.min.js" integrity="sha384-0pUGZvbkm6XF6gxjEnlmuGrJXVbNuzT9qBBavbLwCsOGabYfZo0T0to5eqruptLy" crossorigin="anonymous"></script>


<div class="position-sticky top-0" style="z-index: 10;">
  <nav class="navbar navbar-expand-md bg-body-tertiary shadow-sm">
    <div class="container-fluid">
      <a class="navbar-brand" href="../">MyBiblioteca</a>
      <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
        <span class="navbar-toggler-icon"></span>
      </button>
      <div class="collapse navbar-collapse" id="navbarSupportedContent">
        <ul class="navbar-nav me-auto mb-2 mb-md-0">
          <li class="nav-item">
            <a class="nav-link" href="./">Home</a>
          </li>
          <li class="nav-item">
            <?php
            if ($_SESSION['area'] === 'app') print '<a class="nav-link" href="./catalogo.php">Catalogo</a>';
            else print '<a class="nav-link" href="./utenti.php">Utenti</a>';
            ?>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="./profilo.php">Profilo</a>
          </li>
        </ul>
        <?php
        if ($_SESSION['area'] === 'app')
          print '
            <form class="d-flex" method="get" action="./catalogo.php">
              <input class="form-control me-2" name="search" type="search" placeholder="ISBN / nome libro" value="' . ($_GET['search'] ?? null) . '">
              <button class="btn btn-outline-primary" type="submit">Cerca</button>
            </form>';
        ?>
      </div>
    </div>
  </nav>
</div>