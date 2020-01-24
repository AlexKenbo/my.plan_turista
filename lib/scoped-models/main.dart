import 'package:scoped_model/scoped_model.dart';

import './connected_vacation.dart';

class MainModel extends Model with ConnectedEventsModel, UserModel, EventsModel, UtilityModel, VacationModel {
  
}