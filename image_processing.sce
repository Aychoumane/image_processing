// ------------------------------
// Projet Interface avec traitement d'images
// ------------------------------

atomsLoad('IPCV');

// --- Sélection de la taille de la fenêtre ---
labels = ["Petite", "Moyenne", "Grande", "Par défaut"];
title = "Choix de la taille de l''interface";

rep = x_choose(labels, title);

// Si l'utilisateur ferme la boîte sans choisir
if rep == 0 then
    messagebox("Aucune taille sélectionnée. Le programme va s''arrêter.", ...
               "Annulation", "error");
    abort;
end

// Ajustement du facteur d’échelle selon le choix
select rep
    case 1
        fig_scale = 0.5;
    case 2
        fig_scale = 0.7;
    case 3
        fig_scale = 0.9;
    case 4
        fig_scale = 0.8; // Valeur par défaut
    else
        fig_scale = 0.8; // Sécurité
end

// Vérification du coefficient d'échelle
if fig_scale > 0.9 then
    abort; // Stoppe immédiatement l'exécution du programme
end

// Taille de base
global base_width base_height;
base_width = 900;
base_height = 600;

// Taille réelle
global fig_width fig_height;
fig_width = round(base_width * fig_scale);
fig_height = round(base_height * fig_scale);

// --- Chemin image par défaut ---
global img_path;
img_path = getIPCVpath() + "/images/lena.png";

// --- Création figure principale ---
f = figure("Position", [100, 100, fig_width, fig_height], ...
           "Name", "Projet Image GUI", "resize", "off", ...
           "BackgroundColor", [0.92 0.94 0.96]);

// --- Menu latéral droit ---
menu_width = round(0.25 * fig_width);
menu_bg = uicontrol(f, "style", "frame", ...
                    "position", [fig_width-menu_width, 0, menu_width, fig_height], ...
                    "BackgroundColor", [0.85 0.87 0.90]);

// --- Paramètres boutons ---
button_w = round(160 * fig_scale);
button_h = round(45 * fig_scale);
button_x = fig_width - menu_width + round((menu_width - button_w)/2);
top_margin = round(20 * fig_scale);
btn_spacing = round(25 * fig_scale);

// --- Bouton Charger Image ---
uicontrol(f, "style", "pushbutton", ...
          "string", "Charger Image", ...
          "position", [button_x, fig_height - top_margin - button_h, button_w, button_h], ...
          "BackgroundColor", [0.55 0.70 0.85], ...
          "ForegroundColor", [1 1 1], ...
          "FontSize", round(15*fig_scale), ...
          "TooltipString", "Charger l''image dans le cache", ...
          "callback", "chargerImage()");

// --- Bouton Chercher une autre image ---
btn_chercher_y = fig_height - top_margin - 2*button_h - btn_spacing;
uicontrol(f, "style", "pushbutton", ...
          "string", "Chercher une autre image", ...
          "position", [button_x, btn_chercher_y, button_w, button_h], ...
          "BackgroundColor", [0.55 0.70 0.85], ...
          "ForegroundColor", [1 1 1], ...
          "FontSize", round(15*fig_scale), ...
          "TooltipString", "Chercher une autre image dans l''explorateur de fichiers, appuyez sur charger pour l''afficher", ...
          "callback", "chercherImage()");

// --- Bouton Exporter Image ---
btn_export_y = btn_chercher_y - (button_h + btn_spacing);
uicontrol(f, "style", "pushbutton", ...
          "string", "Exporter Image", ...
          "position", [button_x, btn_export_y, button_w, button_h], ...
          "BackgroundColor", [0.50 0.80 0.70], ... // vert menthe
          "ForegroundColor", [1 1 1], ...
          "FontSize", round(15*fig_scale), ...
          "TooltipString", "Exporter l''image affichée dans un nouveau fichier", ...
          "callback", "exporterImage()");

// --- Barre de séparation ---
sep_y = btn_export_y - 20*fig_scale;
uicontrol(f, "style", "frame", ...
          "position", [fig_width - menu_width + 10, sep_y, menu_width - 20, 2], ...
          "BackgroundColor", [1 1 1]);

// --- Mini-menu déroulant ---
global btn_list;
global btn_list;
btn_list = ["NB"; "Seuillage"; "Contraste";...
            "Tourner90"; "FlipH"; "FlipV"; ...
            "Addition"; "Histogramme"; "Convolution"; ...
            "Eclaircir"; "Assombrir"; "Negatif"; ...
            "Sobel"; "Posterisation"; "Vieillissement"];


// Tableau des infobulles correspondantes
btn_tooltips = [
    "Convertir l''image en noir et blanc";
    "Seuillage de l''image";
    "Amélioration du contraste";
    "Tourner l''image de 90° à droite";
    "Retourner l''image horizontalement";
    "Retourner l''image verticalement";
    "Additionner l''image avec elle même pour augmenter la luminance";
    "Afficher l''histogramme de l''image";
    "Effet flou/ Détection de bords";
    "Augmenter la luminosité (éclaircissement)";
    "Diminuer la luminosité (assombrissement)";
    "Inverser les couleurs (négatif)";
    "Détection de contours avec filtre Sobel";
    "Réduction du nombre de niveaux → effet cartoon";
    "Appliquer un effet sépia (vieillissement photo)";
];


global btn_start_index;
btn_start_index = 1;
visible_count = 3;

// Position du mini-menu
mini_top_y = sep_y - round(60*fig_scale);

// --- Bouton Monter ---
uicontrol(f, "style", "pushbutton", ...
          "string", "Monter", ...
          "position", [button_x, mini_top_y, button_w, button_h], ...
          "BackgroundColor", [0.75 0.85 0.75], ...
          "ForegroundColor", [1 1 1], ...
          "FontSize", round(15*fig_scale), ...
          "callback", "scrollUp()");

// --- Création des boutons du mini-menu ---
global mini_btn_handles;
mini_btn_handles = [];

for i = 1:visible_count
    btn_y = mini_top_y - i*(button_h + btn_spacing);
    btn = uicontrol(f, "style", "pushbutton", ...
                    "string", btn_list(i), ...
                    "position", [button_x, btn_y, button_w, button_h], ...
                    "BackgroundColor", [0.55 0.70 0.85], ...
                    "ForegroundColor", [1 1 1], ...
                    "FontSize", round(15*fig_scale), ...
                    "TooltipString", btn_tooltips(i), ... //infobulle asssocié
                    "callback", btn_list(i) + "()");
    mini_btn_handles = [mini_btn_handles; btn];
end


// --- Bouton Descendre ---
btn_down_y = mini_top_y - (visible_count + 1)*(button_h + btn_spacing);
uicontrol(f, "style", "pushbutton", ...
          "string", "Descendre", ...
          "position", [button_x, btn_down_y, button_w, button_h], ...
          "BackgroundColor", [0.90 0.75 0.75], ...
          "ForegroundColor", [1 1 1], ...
          "FontSize", round(15*fig_scale), ...
          "callback", "scrollDown()");

// ------------------------------------------------------------ESPACE : FONCTIONS DU MENU-----------------------------
funcprot(0);
function NB()
    global image_axes
    sca(image_axes);
    children = gca().children;
    if size(children) <> 0 then
        img_data = children(1).data;
        if size(img_data, 3) == 3 then
            gray_img = rgb2gray(img_data);
        else
            gray_img = img_data;
        end
        imshow(gray_img);
        disp("Image convertie en noir et blanc !");
    else
        disp("Aucune image chargée !");
    end
endfunction

function Seuillage()
    global image_axes
    sca(image_axes);
    children = gca().children;
    if size(children) == 0 then
        disp("Aucune image chargée !");
        return
    end

    img_data = children(1).data;

    // Conversion en niveaux de gris si nécessaire
    if size(img_data, 3) == 3 then
        gray_img = rgb2gray(img_data);
    else
        gray_img = img_data;
    end

    // Seuillage fixe à 128 (sur 8 bits)
    threshold = 128;
    binary_img = gray_img > threshold;

    // Convertir en uint8 pour affichage
    binary_img = uint8(binary_img * 255);

    // Afficher le résultat
    imshow(binary_img);
    disp("Seuillage effectué ( seuil fixe = 128 )")
endfunction


function Contraste()
    global image_axes
    sca(image_axes);
    children = gca().children;

    if size(children) == 0 then
        disp("Aucune image chargée !");
        return
    end

    // Récupérer l'image
    img_data = children(1).data;

    // Déterminer si image couleur ou non
    dims = ndims(img_data);

    if dims == 3 then
        [h, w, c] = size(img_data);
        img_prime = uint8(zeros(h, w, c));

        for k = 1:c
            channel = double(img_data(:,:,k)); // en double pour calcul
            imin = min(channel(:));            // min global
            imax = max(channel(:));            // max global

            if imax == imin then
                img_prime(:,:,k) = uint8(channel);
            else
                // Étirement linéaire de la dynamique
                img_prime(:,:,k) = uint8((channel - imin) * 255 / (imax - imin));
            end
        end

    else
        // Image en niveaux de gris
        gray = double(img_data);
        imin = min(gray(:));
        imax = max(gray(:));

        if imax == imin then
            img_prime = uint8(gray);
        else
            img_prime = uint8((gray - imin) * 255 / (imax - imin));
        end
    end

    // Réaffichage 
    delete(children);
    imshow(img_prime);
    disp("Amélioration du contraste effectué.")
endfunction


// ---Tourner 90° à droite ---
function Tourner90()
    global image_axes fig_width fig_height
    sca(image_axes);
    children = gca().children;
    if size(children) <> 0 then
        img_data = children(1).data;

        // Supprimer l'image existante
        delete(children);

        // Rotation 90° à droite
        if size(img_data, 3) == 3 then
            img_rot = uint8(zeros(size(img_data,2), size(img_data,1), 3));
            for k = 1:3
                img_rot(:,:,k) = img_data(:,:,k)';
                img_rot(:,:,k) = img_rot(:, $:-1:1, k);
            end
        else
            img_rot = uint8(zeros(size(img_data,2), size(img_data,1)));
            img_rot = img_data';
            img_rot = img_rot(:, $:-1:1);
        end

        // Redimensionner pour l’axe (comme dans chargerImage)
        new_w = round(0.75 * fig_width);
        new_h = fig_height;
        img_resized = imresize(img_rot, [new_h, new_w]);

        // Afficher
        imshow(img_resized);
        disp("Image tournée de 90° à droite !");
    else
        disp("Aucune image chargée !");
    end
endfunction


// --- Flip horizontal ---
function FlipH()
    global image_axes
    sca(image_axes);
    children = gca().children;
    if size(children) <> 0 then
        img_data = children(1).data;
        img_flip = img_data(:, $:-1:1, :); // flip horizontal
        imshow(img_flip);
        disp("Image retournée horizontalement !");
    else
        disp("Aucune image chargée !");
    end
endfunction

// --- Flip vertical ---
function FlipV()
    global image_axes
    sca(image_axes);
    children = gca().children;
    if size(children) <> 0 then
        img_data = children(1).data;
        img_flip = img_data($:-1:1, :, :); // flip vertical
        imshow(img_flip);
        disp("Image retournée verticalement !");
    else
        disp("Aucune image chargée !");
    end
endfunction

function Addition()
    global image_axes
    sca(image_axes);
    children = gca().children;

    if size(children) == 0 then
        disp("Aucune image chargée !");
        return
    end

    // Lecture de l'image affichée
    img_data = double(children(1).data);

    // --- Addition de l'image avec elle-même ---
    img_sum = img_data + img_data;

    // Normalisation pour rester dans [0,255]
    max_val = max(img_sum(:));
    if max_val > 255 then
        img_sum = img_sum * (255 / max_val);
    end

    // Conversion en entier 8 bits
    img_sum = uint8(img_sum);

    // Réaffichage
    delete(children);
    imshow(img_sum);

    disp("Addition effectuée : image + elle-même (luminance augmentée)");
endfunction


function Histogramme()
    global image_axes
    children = gca().children;

    // Vérification qu'une image est chargée
    if size(children) == 0 then
        disp("Aucune image chargée.");
        return
    end

    // Lecture de l'image affichée
    img_data = double(children(1).data);

    // Conversion en niveaux de gris si couleur
    if size(img_data, 3) == 3 then
        img_gray = rgb2gray(img_data);
    end
    if size(img_data, 3) <> 3 then
        img_gray = img_data;
    end

    // Création d'une nouvelle fenêtre pour l'histogramme
    f_hist = figure("Name", "Histogramme", "Position", [200, 200, 500, 400]);

    // Calcul et affichage de l'histogramme
    n_bins = 256;
    histplot(n_bins, double(img_gray(:)));

    xlabel("Intensité");
    ylabel("Nombre de pixels");
    title("Histogramme de l''image");

    disp("Histogramme affiché.");
endfunction

function Convolution()
    global image_axes
    children = gca().children;

    // Vérifier qu'une image est chargée
    if size(children) == 0 then
        disp("Aucune image chargée.");
        return
    end

    // Lire l'image
    img_data = double(children(1).data);

    // Conversion en niveaux de gris si couleur
    if size(img_data, 3) == 3 then
        img_gray = rgb2gray(img_data);
    end
    if size(img_data, 3) <> 3 then
        img_gray = img_data;
    end

    // Exemple de noyau : flou 3x3
    K = [1 1 1; 1 1 1; 1 1 1]/9;

    // Convolution
    img_conv = conv2(img_gray, K, 'same'); // 'same' = garde la taille originale

    // Clip pour rester dans [0,255]
    img_conv(img_conv < 0) = 0;
    img_conv(img_conv > 255) = 255;

    // Conversion en entier 8 bits
    img_conv = uint8(img_conv);

    // Affichage dans la zone principale
    delete(children);
    imshow(img_conv);

    disp("Convolution appliquée.");
endfunction


function Eclaircir()
    global image_axes
    sca(image_axes);
    children = gca().children;

    if size(children) == 0 then
        disp("Aucune image chargée !");
        return
    end

    img = double(children(1).data);

    img2 = img + 20;
    img2 = min(img2, 255);
    img2 = uint8(img2);

    delete(children);
    imshow(img2);

    disp("Éclaircissement effectué (+20).");
endfunction


function Assombrir()
    global image_axes
    sca(image_axes);
    children = gca().children;

    if size(children) == 0 then
        disp("Aucune image chargée !");
        return
    end

    img = double(children(1).data);

    img2 = img - 20;
    img2 = max(img2, 0);
    img2 = uint8(img2);

    delete(children);
    imshow(img2);

    disp("Assombrissement effectué (-20).");
endfunction


function Negatif()
    global image_axes
    sca(image_axes);
    children = gca().children;

    if size(children) == 0 then
        disp("Aucune image chargée !");
        return
    end

    img = double(children(1).data);

    img2 = 255 - img;
    img2 = uint8(img2);

    delete(children);
    imshow(img2);

    disp("Image transformée en négatif.");
endfunction


function Sobel()
    global image_axes
    sca(image_axes);
    children = gca().children;

    if size(children) == 0 then
        disp("Aucune image chargée !");
        return
    end

    img = double(children(1).data);

    if size(img, 3) == 3 then
        img = rgb2gray(img);
    end

    Kx = [-1 0 1; -2 0 2; -1 0 1];
    Ky = [-1 -2 -1; 0  0  0; 1  2  1];

    Gx = conv2(img, Kx, "same");
    Gy = conv2(img, Ky, "same");

    G = sqrt(Gx.^2 + Gy.^2);
    G = G ./ max(G) * 255;

    delete(children);
    imshow(uint8(G));

    disp("Filtre Sobel appliqué (détection de contours).");
endfunction


function Posterisation()
    global image_axes
    sca(image_axes);
    children = gca().children;

    if size(children) == 0 then
        disp("Aucune image chargée !");
        return
    end

    img = double(children(1).data);

    if size(img, 3) == 3 then
        img = rgb2gray(img);
    end

    nb = 4;
    step = 255 / (nb - 1);

    img_p = round(img / step) * step;

    delete(children);
    imshow(uint8(img_p));

    disp("Postérisation effectuée (4 niveaux).");
endfunction


function Vieillissement()
    global image_axes
    sca(image_axes);
    children = gca().children;

    if size(children) == 0 then
        disp("Aucune image chargée !");
        return
    end

    img = double(children(1).data);

    if size(img, 3) <> 3 then
        disp("L''effet sépia nécessite une image couleur.");
        return
    end

    R = img(:,:,1);
    G = img(:,:,2);
    B = img(:,:,3);

    R2 = 0.393*R + 0.769*G + 0.189*B;
    G2 = 0.349*R + 0.686*G + 0.168*B;
    B2 = 0.272*R + 0.534*G + 0.131*B;

    R2 = min(R2, 255);
    G2 = min(G2, 255);
    B2 = min(B2, 255);

    img_out = cat(3, uint8(R2), uint8(G2), uint8(B2));

    delete(children);
    imshow(img_out);

    disp("Effet sépia / vieillissement appliqué.");
endfunction



// ---gestion du mini menu ---
function updateVisibleButtons()
    global btn_list btn_tooltips btn_start_index visible_count mini_btn_handles
    n_btn = size(btn_list,1);
    for i = 1:visible_count
        idx = btn_start_index + i - 1;
        if idx <= n_btn then
            btn = mini_btn_handles(i);
            set(btn, "string", btn_list(idx));
            set(btn, "callback", btn_list(idx) + "()");
            set(btn, "TooltipString", btn_tooltips(idx));
            set(btn, "visible", "on");
        else
            set(mini_btn_handles(i), "visible", "off");
        end
    end
endfunction


// --- Défilement par 3 ---
function scrollUp()
    global btn_start_index visible_count btn_list
    if btn_start_index > 1 then
        btn_start_index = max(1, btn_start_index - visible_count);
        updateVisibleButtons();
    end
    // Affichage de la page courante
    n_btn = size(btn_list,1);
    nb_pages = ceil(n_btn / visible_count);
    current_page = ceil(btn_start_index / visible_count);
    disp("Page " + string(current_page) + " / " + string(nb_pages));
endfunction

function scrollDown()
    global btn_start_index btn_list visible_count
    n_btn = size(btn_list,1);
    if btn_start_index + visible_count - 1 < n_btn then
        btn_start_index = min(n_btn - visible_count + 1, btn_start_index + visible_count);
        updateVisibleButtons();
    end
     // Affichage de la page courante
    nb_pages = ceil(n_btn / visible_count);
    current_page = ceil(btn_start_index / visible_count);
    disp("Page " + string(current_page) + " / " + string(nb_pages));
endfunction

// --- gestion image ---
global image_axes;
image_axes = newaxes(f);
image_axes.axes_bounds = [0, 0, 0.75, 1];
image_axes.axes_visible = "off";

// --- Effacer zone image ---
function clearImageZone()
    global image_axes
    sca(image_axes);
    delete(gca().children);
endfunction

// --- Charger image ---
function chargerImage()
    global img_path image_axes fig_width fig_height
    clearImageZone();
    sca(image_axes);
    img = imread(img_path);
    new_w = round(0.75 * fig_width);
    new_h = fig_height;
    img_resized = imresize(img, [new_h, new_w]);
    imshow(img_resized);
endfunction

// --- Chercher image ---
function chercherImage()
    global img_path
    exts = ["*.png"; "*.jpg"; "*.jpeg"; "*.bmp"];
    file_path = uigetfile(exts, "Choisir une image");
    if file_path <> "" then
        img_path = file_path;
    end
endfunction

// --- Exporter image ---
function exporterImage()
    global img_path image_axes
    children = gca().children;
    if size(children) == 0 then
        disp("Aucune image à exporter !");
        return
    end

    img_data = children(1).data;

    // Extraire dossier et nom du fichier original
    [path, name, ext] = fileparts(img_path);

    // Créer timestamp
    t = getdate();
    timestamp = msprintf("%04d%02d%02d_%02d%02d%02d%03d", ...
                         t(1), t(2), t(6), t(7), t(8), t(9), t(10));

    // Construire le nouveau nom
    new_name = name + "_modified_" + timestamp + ext;
    new_path = path + filesep() + new_name;

    // Sauvegarder l’image
    imwrite(img_data, new_path);
    disp("Image exportée : " + new_path) ; 
endfunction
