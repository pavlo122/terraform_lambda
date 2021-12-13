'use strict';

const urlMap = (mapuri) => ({
    '/test/': '/test2/',
    '/test1/': '/test4/',
    '/test3/': '/test/3/'
})[mapuri]

exports.handler = (event, context, callback) => {
    let request = event.Records[0].cf.request;
    if (urlMap(request.uri) != null) {
        const redirectResponse = {
            status: '301',
            statusDescription: 'Moved Permanently',
            headers: {
            'location': [{
                key: 'Location',
                value: urlMap(request.uri),
            }],
            'cache-control': [{
                key: 'Cache-Control',
                value: "max-age=3600"
            }],
            },
        };
        callback(null, redirectResponse);
    }
    // S3 static web sites know only DefaultRootObject for / but not for subfolders. So this part is ussually needed
    if (request.uri.endsWith('/')) {
        request.uri += 'index.html';
    }
    else if (!request.uri.includes('.')) {
        request.uri += '/index.html';
    }
    callback(null, request);
};