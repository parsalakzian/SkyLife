class ForecastDaysModel {

  var _dataTime;
  var _temp;
  String _main;
  String _description;
  var _icon;
  var _dth;


	ForecastDaysModel(
    this._main,
    this._description,
    this._temp,
    this._dataTime,
    this._icon,
    this._dth,
  );

  
  String get main => _main;
  String get description => _description;
  get dataTime => _dataTime;
  get temp => _temp;
  get icon => _icon;
  get dth => _dth;



}