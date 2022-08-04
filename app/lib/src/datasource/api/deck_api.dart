import 'package:chopper/chopper.dart';
import 'package:memento_studio/src/entities.dart';
part 'deck_api.chopper.dart';

typedef DeckList = List<ApiDeck>;

@ChopperApi(baseUrl: "/decks")
abstract class DeckApi extends ChopperService {
  @Get(path: "")
  Future<Response<DeckList>> getDecks(@Body() Map<String, int> pagination);

  @Post(path: "", headers: {"Content-Type": "multipart/form-data"})
  @multipart
  Future<Response<ApiDeck>> postDeck(
      @Part("deck") var deck, @PartFileMap() var images);

  @Put(path: "/{id}", headers: {"Content-Type": "multipart/form-data"})
  @multipart
  Future<Response<ApiDeck>> putDeck(
    @Path("id") String deckId,
    @Part("deck") String deckUpdates,
    @PartFileMap() var images,
  );

  @Delete(path: "/{id}")
  Future<Response<Map<String, dynamic>>> deleteDeck(@Path("id") String deckId);

  @Post(path: "/copy/{id}")
  Future<Response<ApiDeck>> copyDeck(@Path("id") String deckId);

  static DeckApi create([ChopperClient? client]) => _$DeckApi(client);
}
