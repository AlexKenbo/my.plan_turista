import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import '../../models/event.dart';

class ImageInput extends StatefulWidget {
  final Function setImage;
  final Event event;

  ImageInput(this.setImage, this.event);

  @override
  _ImageInputState createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  File _imageFile;

  void _getImage(BuildContext context, ImageSource source) {
    ImagePicker.pickImage(source: source, maxWidth: 400.0).then((File image) {
      setState(() {
        _imageFile = image;
      });
      widget.setImage(image);
      Navigator.pop(context);
    });
  }

  void _openImagePicker(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 250.0,
            padding: EdgeInsets.all(10.0),
            child: Column(
              children: <Widget>[
                FlatButton(
                  //textColor: Theme.of(context).primaryColor,
                  child: Text('Использовать камеру'),
                  onPressed: () {
                    _getImage(context, ImageSource.camera);
                  },
                ),
                FlatButton(
                  //textColor: Theme.of(context).primaryColor,
                  child: Text('Использовать фотогалерею'),
                  onPressed: () {
                    _getImage(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = Theme.of(context).accentColor;
    Widget previewImage = Text('Пожалуйста добавьте фото', style: TextStyle(color: Color.fromARGB(125, 160, 160, 160),),);
    if (_imageFile != null) {
      previewImage = Image.file(
        _imageFile,
        fit: BoxFit.cover,
        height: 300.0,
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.topCenter,
      );
    } else if (widget.event != null) {
      previewImage =Image.network(widget.event.image,
          fit: BoxFit.cover,
          height: 300.0,
          width: MediaQuery.of(context).size.width,
          alignment: Alignment.topCenter,
      );
    }

    return Column(
      children: <Widget>[
        OutlineButton(
          borderSide:
              BorderSide(color: Theme.of(context).accentColor, width: 2.0),
          onPressed: () {
            _openImagePicker(context);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.camera_alt, color: buttonColor),
              SizedBox(
                width: 5.0,
              ),
              Text(
                'Добавить фото',
                style: TextStyle(color: buttonColor),
              )
            ],
          ),
        ),
        SizedBox(
          height: 10.0,
        ),
        previewImage,
      ],
    );
  }
}
