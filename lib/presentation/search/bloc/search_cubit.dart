import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spotify/domain/usecases/search_songs_usecase.dart';
import 'package:spotify/presentation/search/bloc/search_state.dart';

import '../../../service_locator.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(SearchInitial());

  Future<void> searchSongs(String query) async {
    if (query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());
    
    var result = await sl<SearchSongsUseCase>().call(params: query.trim());
    
    result.fold(
      (error) {
        emit(SearchError(message: error.toString()));
      },
      (songs) {
        emit(SearchLoaded(songs: songs));
      },
    );
  }

  void clearSearch() {
    emit(SearchInitial());
  }
}

