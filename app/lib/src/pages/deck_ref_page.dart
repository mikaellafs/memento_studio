import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:memento_studio/src/entities.dart';

import 'package:memento_studio/src/repositories.dart';
import 'package:memento_studio/src/state_managers.dart';
import 'package:uuid/uuid.dart';

class DeckRefPage extends StatefulWidget {
  final Deck deck;

  const DeckRefPage({
    Key? key,
    required this.deck,
  }) : super(key: key);

  @override
  State<DeckRefPage> createState() => _DeckRefPageState();
}

class _DeckRefPageState extends State<DeckRefPage> {
  final DeckRepositoryInterface apiRepo = KiwiContainer().resolve();
  final DeckCollectionCubit collectionCubit = KiwiContainer().resolve();
  final AuthCubit auth = KiwiContainer().resolve();

  @override
  Widget build(BuildContext context) {
    var tags = widget.deck.tags.isNotEmpty ? widget.deck.tags : ["Sem Tags"];

    dynamic imageCover = getDeckCover();

    var popUpMenu = PopupMenuButton(
        itemBuilder: (context) => [
              const PopupMenuItem<int>(
                value: 0,
                child: Text("Fazer uma cópia"),
              )
            ],
        onSelected: (_) {
          showCopyDeckDialog();
        });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        actions: [popUpMenu],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            imageCover,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.deck.name,
                    style: const TextStyle(fontSize: 32.0),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    widget.deck.description ?? "",
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 10.0),
                  Wrap(
                    spacing: 4.0,
                    runSpacing: -10.0,
                    children: [for (var tag in tags) Chip(label: Text(tag))],
                  ),
                  const SizedBox(height: 5.0),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Por Fulano de tal",
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${widget.deck.cards.length} cartas",
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getDeckCover() {
    bool shouldShowImage =
        widget.deck.cover != null && widget.deck.cover!.isNotEmpty;
    var imageHeight = 300.0;

    var placeholderImage = const BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/images/placeholder.png"),
        fit: BoxFit.cover,
      ),
    );

    if (shouldShowImage && !widget.deck.cover!.contains('http')) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File(widget.deck.cover!)),
            fit: BoxFit.cover,
          ),
        ),
        height: imageHeight,
      );
    } else if (!shouldShowImage) {
      return Container(
        decoration: placeholderImage,
        height: imageHeight,
      );
    }

    return CachedNetworkImage(
      fit: BoxFit.cover,
      width: MediaQuery.of(context).size.width,
      height: imageHeight,
      imageUrl: widget.deck.cover ?? "",
      placeholder: (context, url) =>
          const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => Container(
        decoration: placeholderImage,
      ),
    );
  }

  void showCopyDeckDialog() {
    showDialog<String>(
      context: context,
      builder: (BuildContext copyContext) => AlertDialog(
        title: Text.rich(
          TextSpan(
            text: "Deseja fazer uma cópia de ",
            children: <TextSpan>[
              TextSpan(
                text: "'${widget.deck.name}'",
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const TextSpan(text: "?")
            ],
          ),
        ),
        content: Text.rich(
          TextSpan(
            text: "Uma cópia do baralho ",
            children: <TextSpan>[
              TextSpan(
                text: "'${widget.deck.name}'",
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const TextSpan(text: " será adicionada a sua coleção.")
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancelar'),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Tira dialog para mostrar loading
              showLoadingDialog();

              var isThereError = false;

              if (auth.state is Authenticated) {
                var result = await apiRepo
                    .copyDeck(widget.deck.id); // Salva baralho no servidor

                if (result is Error) {
                  isThereError = true; // Tratar melhor esse erro talvez
                } else if (result is Success) {
                  var copy = (result as Success).value as Deck;

                  await collectionCubit.createDeck(copy);
                }
              } else {
                await collectionCubit.createDeck(
                  widget.deck.copyWith(
                    id: const Uuid().v4().toString(),
                  ),
                );
              }

              Navigator.pop(context); // Retira loading
              if (isThereError) {
                showOkWithIconDialog(
                  "Falha ao salvar baralho no servidor",
                  "Não foi possível fazer a cópia do baralho no servidor. Tente sincronizar mais tarde.",
                  icon: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 50.0,
                    semanticLabel: 'Error',
                  ),
                );
              } else {
                showOkWithIconDialog(
                  "Cópia feita com sucesso",
                  "Uma cópia deste baralho foi adicionada a sua coleção.",
                  icon: const Icon(
                    Icons.task_alt,
                    color: Colors.green,
                    size: 50.0,
                    semanticLabel: 'Success',
                  ),
                );
              }
            },
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );
  }

  void showTurnPublicDialog() {
    showDialog<String>(
      context: context,
      builder: (BuildContext pcontext) => AlertDialog(
        title: const Text('Tornar baralho público?'),
        content: const Text(
            "Ao confirmar, esse baralho ficará disponível para outros usuários utilizarem e clonarem em suas próprias coleções. Lembre-se de sincronizar o baralho antes de torná-lo público. Tem certeza disso?"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancelar'),
            child: const Text('Não', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Tira dialog para mostrar loading
              showLoadingDialog();

              if (auth.state is Authenticated) {
                var result = await apiRepo.updateDeck(
                  widget.deck.id,
                  <String, bool>{"isPublic": true},
                  <String, Uint8List>{},
                );

                Navigator.pop(context);

                if (result is Error) {
                  showOkWithIconDialog(
                    "Falha ao tornar baralho público",
                    "Não foi possível tornar este baralho público. Tente novamente mais tarde.",
                    icon: const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 50.0,
                      semanticLabel: 'Error',
                    ),
                  );
                } else if (result is Success) {
                  showOkWithIconDialog(
                    "Baralho público com sucesso",
                    "Agora este baralho é público e outras pessoas poderão utilizá-lo.",
                    icon: const Icon(
                      Icons.task_alt,
                      color: Colors.green,
                      size: 50.0,
                      semanticLabel: 'Success',
                    ),
                  );
                }
              } else {
                Navigator.pop(context);
                showOkWithIconDialog("Usuário não logado",
                    "Você precisa estar logado para tornar este baralho público.");
              }
            },
            child: const Text("Sim"),
          ),
        ],
      ),
    );
  }

  void showLoadingDialog() {
    showDialog(
        // The user CANNOT close this dialog  by pressing outsite it
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return Dialog(
            // The background color
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  // The loading indicator
                  CircularProgressIndicator(),
                  SizedBox(
                    height: 15,
                  ),
                  // Some text
                  Text('Loading...')
                ],
              ),
            ),
          );
        });
  }

  void showOkWithIconDialog(String title, String subtitle, {Icon? icon}) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          height: 130,
          child: Column(
            children: [
              icon ?? Container(),
              const SizedBox(height: 15.0),
              Text(subtitle),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'OK'),
            child: const Text("Ok"),
          ),
        ],
      ),
    );
  }
}
