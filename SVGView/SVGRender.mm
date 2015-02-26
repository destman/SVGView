//
//  SVGRender.cpp
//  SVGViewTest
//
//  Created by Arkadiy Tolkun on 31.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include "SVGRender.h"
#include <list>

SVGRender::SVGRender()
{
    _colorSpace = CGColorSpaceCreateDeviceRGB();
}

SVGRender::~SVGRender()
{
    CGColorSpaceRelease(_colorSpace);
    closeFile();
}

void SVGRender::closeFile()
{
    for (map<const ProtoSVGElementPath*, CGPathRef>::iterator it = _pathMap.begin(); it!=_pathMap.end(); it++) 
    {
        CGPathRelease(it->second);
    }
    _pathMap.clear();
    for (map<const ProtoSVGElementGradient*, CGGradientRef>::iterator it =_gradientMap.begin(); it!=_gradientMap.end(); it++) 
    {
        CGGradientRelease(it->second);
    }
    _gradientMap.clear();        
    _root.Clear();
}

set<int> SVGRender::statesFromName(const string &name)
{
    set<int> rv;
    size_t start=name.find("state-");
    if(start!=string::npos)
    {
        const char *str=name.c_str()+start+6;
        char *nextNumber = 0;
        while (*str!=0)
        {
            long state = strtol(str, &nextNumber, 10);
            if(nextNumber==str) break;
            if(nextNumber==0) break;             
            rv.insert(state);
            
            //Guard against Adobe Illustarator additional symbols like [...]_1_
            if(*nextNumber!=0)
            {
                if(*nextNumber=='-')
                {
                    str = nextNumber+1;
                }else
                {
                    break;
                }
            }else
            {
                break;
            }
        }            
    }    
    return rv;
}


bool SVGRender::openFile(const char *name)
{
    bool rv = false;
    closeFile();
    PBFileInputStream stream;
    if(stream.open(name))
    {
        rv = _root.ParseFromZeroCopyStream(&stream); 
    }
    
    enumElements(^bool(const ProtoSVGElement *object) 
    {
        if(object->has_group()&&object->group().has_id())
        {
            set<int> states = statesFromName(object->group().id());
            _allStates.insert(states.begin(),states.end());
        }
        return true;
    }, nullptr, false);
    return rv;
}


//return true if need to restore state
bool SVGRender::prepareToDraw(CGContextRef context,const ProtoSVGGeneralParams *object)
{
    if(object->has_opacity() || object->has_transform())
    {
        CGContextSaveGState(context);
        
        if(object->has_transform())
        {
            const ProtoAffineTransformMatrix *t = &object->transform();
            float a=1,b=0,c=0,d=1,tx=0,ty=0;
            if (t->has_a())
                a = t->a();
            if (t->has_b())
                b = t->b();
            if (t->has_c())
                c = t->c();
            if (t->has_d())
                d = t->d();
            if (t->has_tx())
                tx = t->tx();
            if (t->has_ty())
                ty = t->ty();
            CGAffineTransform transform = CGAffineTransformMake(a, b, c, d, tx, ty);
            CGContextConcatCTM(context, transform);
        }
        if(object->has_opacity())
        {
            CGContextSetAlpha(context, object->opacity());    
        }
        return true;
    }
    return false;
}

CGPathRef SVGRender::buildCGPath(const ProtoSVGElementPath *path)
{
    CGMutablePathRef rv = CGPathCreateMutable();
    
    if(path->points_size()!=0) //this is path with points
    {
        for (int i=0; i<path->points_size(); i++)
        {
            const ProtoSVGElementPath_PathPoint *point=&path->points(i);
            if(point->has_move_to())
            {
                CGPathMoveToPoint(rv, 0, point->move_to().x(), point->move_to().y());
            }
            if(point->has_line_to())
            {
                CGPathAddLineToPoint(rv, 0, point->line_to().x(), point->line_to().y());
            }
            if(point->has_curve_to())
            {
                const ProtoCurve *c = &point->curve_to();
                CGPathAddCurveToPoint(rv, 0, c->cp1x(), c->cp1y(), c->cp2x(), c->cp2y(), c->x(), c->y());
            }
            if(point->has_close_path() && point->close_path())
            {
                CGPathCloseSubpath(rv);
            }
        }
    }
    
    if(path->has_r()) //this is circle
    {
        CGRect rt = CGRectMake(path->cx(), path->cy(), path->r()*2, path->r()*2);
        rt.origin.x -= path->r();
        rt.origin.y -= path->r();
        CGPathAddEllipseInRect(rv, 0, rt);
    }
    
    if(path->has_rx() && path->has_ry()) //this is ellipse
    {
        CGRect rt = CGRectMake(path->cx(), path->cy(), path->rx()*2, path->ry()*2);
        rt.origin.x -= path->rx();
        rt.origin.y -= path->ry();
        CGPathAddEllipseInRect(rv, 0, rt);
    }
    if(path->has_rect()) //this is rect
    {
        CGRect rt = CGRectMake(path->rect().x(), path->rect().y(), path->rect().w(), path->rect().h());
        CGPathAddRect(rv, 0, rt);
    }
    return rv;
}


CGPathRef SVGRender::getCGPathForPath(const ProtoSVGElementPath *path)
{
    CGPathRef rv = 0;
    map<const ProtoSVGElementPath*, CGPathRef>::iterator it = _pathMap.find(path);
    if(it!=_pathMap.end())
    {
        rv = it->second;
    }
    if(rv == 0)
    {
        rv = buildCGPath(path);
        if(rv)
        {
            _pathMap.insert(pair<const ProtoSVGElementPath*, CGPathRef>(path,rv));
        }
    }
    return rv;
}

CGGradientRef SVGRender::buildCGGradient(const ProtoSVGElementGradient *gradient)
{
    CGFloat *locs  = (CGFloat *)malloc(sizeof(CGFloat)*gradient->stops_size());
    CGFloat *cols  = (CGFloat *)malloc(sizeof(CGFloat)*gradient->stops_size()*4);
    
    for (int i=0;i<gradient->stops_size();i++)
    {
        const ProtoSVGElementGradient_GradientStop *stop = &gradient->stops(i);
        locs[i] = stop->offset();
        cols[i*4+0] = stop->color().r();
        cols[i*4+1] = stop->color().g();
        cols[i*4+2] = stop->color().b();
        if(stop->has_alpha())
        {
            cols[i*4+3] = stop->alpha();
        }else
        {
            cols[i*4+3] = 1;
        }
        cols[i*4+0] /= 255;
        cols[i*4+1] /= 255;
        cols[i*4+2] /= 255;
    }
    CGGradientRef rv = CGGradientCreateWithColorComponents(_colorSpace, cols, locs, gradient->stops_size());
    free(locs);
    free(cols);
    return rv;
}


CGGradientRef SVGRender::getCGGradientForGradient(const ProtoSVGElementGradient *gradient)
{
    CGGradientRef rv = 0;
    map<const ProtoSVGElementGradient*, CGGradientRef>::iterator it = _gradientMap.find(gradient);
    if(it!=_gradientMap.end())
    {
        rv = it->second;
    }
    
    if(rv == 0)
    {
        rv = buildCGGradient(gradient);
        if(rv)
        {
            _gradientMap.insert(pair<const ProtoSVGElementGradient*, CGGradientRef>(gradient,rv));
        }
    }
    return rv;
}


const ProtoSVGElement *SVGRender::findElementById(const string &name)
{
    __block const ProtoSVGElement *rv = nil;
    enumElements(^bool(const ProtoSVGElement *object) 
    {
        if(object->has_gradient())
        {
            if(object->gradient().has_params() && object->gradient().params().has_id() 
               && object->gradient().params().id()==name)
            {
                rv = object;
                return false;
            }
        }
        return true;
    }, nullptr, false);
    
    if(!rv)
    {
        dbgLog(@"Failed to find %s",name.c_str());
    }
    return rv;
}

void SVGRender::prepareToDrawData()
{
    enumElements(^(const ProtoSVGElement *object) 
    {
        if(object->has_gradient())
        {
            getCGGradientForGradient(&object->gradient());   
        }
        if(object->has_path())
        {
            getCGPathForPath(&object->path());
        }        
        return true;
    }, nullptr, false);
}

void SVGRender::drawPath(CGContextRef context,const ProtoSVGElementPath *pathObject, RenderContext &rc)
{
    CGPathRef path = getCGPathForPath(pathObject);
    if(path)
    {
        const ProtoSVGGeneralParams *params = &pathObject->params();
        bool needRestore = prepareToDraw(context, params);

        if (params->has_fill()) {
            rc.fill.MergeFrom(params->fill());
            if (params->fill().has_color()) {
                rc.fill.clear_paint_off();
            }
        }
        const ProtoSVGPaint *fill= &rc.fill;
        if(fill->has_color() || fill->has_odd() || fill->has_paint_off() || fill->has_ref_id() || fill->has_stroke_width())
        {
            if(!fill->paint_off())
            {
                CGContextSaveGState(context);
                
                CGContextAddPath(context,path);
                CGPathDrawingMode   mode   = kCGPathFill;
                if(fill->has_odd() && fill->odd())
                {
                    mode = kCGPathEOFill;
                }                        
                if(fill->has_color())
                {
                    CGFloat rgb[4] = {(CGFloat)fill->color().r(),(CGFloat)fill->color().g(),(CGFloat)fill->color().b(), 1};
                    rgb[0] /= 255;
                    rgb[1] /= 255;
                    rgb[2] /= 255;
                    CGContextSetFillColorSpace(context, _colorSpace);
                    CGContextSetFillColor(context, rgb);
                    CGContextDrawPath(context, mode);
                }else if(fill->has_ref_id())
                {
                    const ProtoSVGElement *element = findElementById(fill->ref_id());
                    if(element && element->has_gradient())
                    {
                        const ProtoSVGElementGradient *fillGradient=&element->gradient();
                        CGGradientRef gradient = getCGGradientForGradient(fillGradient);
                        CGContextClip(context);
                        if(fillGradient->has_gradienttransform())
                        {
                            const ProtoAffineTransformMatrix *t = &fillGradient->gradienttransform();
                            CGAffineTransform transform = CGAffineTransformMake(t->a(), t->b(), t->c(), t->d(), t->tx(), t->ty());
                            CGContextConcatCTM(context, transform);
                        }
                        if(fillGradient->has_startpoint() && fillGradient->has_endpoint())
                        {
                            CGPoint startPoint  = CGPointMake(fillGradient->startpoint().x(), fillGradient->startpoint().y());
                            CGPoint endPoint    = CGPointMake(fillGradient->endpoint().x(), fillGradient->endpoint().y());
                            CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsBeforeStartLocation|kCGGradientDrawsAfterEndLocation);
                        }else if(fillGradient->has_center() && fillGradient->has_r())
                        {
                            CGPoint center  = CGPointMake(fillGradient->center().x(), fillGradient->center().y());
                            float   r = fillGradient->r();
                            
                            if(fillGradient->has_focuspoint())
                            {
                                CGPoint focus  = CGPointMake(fillGradient->focuspoint().x(), fillGradient->focuspoint().y());
                                CGContextDrawRadialGradient(context, gradient, focus, 0, center, r, kCGGradientDrawsBeforeStartLocation|kCGGradientDrawsAfterEndLocation);
                                
                            }else
                            {
                                CGContextDrawRadialGradient(context, gradient, center, 0, center, r, kCGGradientDrawsBeforeStartLocation|kCGGradientDrawsAfterEndLocation);
                                
                            }
                            
                        }
                    }
                }else
                {
                    CGFloat defaultFillColor[4] = {0,0,0,1};
                    CGContextSetFillColorSpace(context, _colorSpace);
                    CGContextSetFillColor(context, defaultFillColor);
                    CGContextDrawPath(context, kCGPathEOFill);
                }
                
                CGContextRestoreGState(context);                    
            }                    
        }else
        {
            CGContextSaveGState(context);
            CGContextAddPath(context,path);                
            CGFloat defaultFillColor[4] = {0,0,0,1};
            CGContextSetFillColorSpace(context, _colorSpace);
            CGContextSetFillColor(context, defaultFillColor);      
            CGContextDrawPath(context, kCGPathFill);                    
            CGContextRestoreGState(context);                
        }
        
        
        if(params->has_stroke())
        {
            const ProtoSVGPaint *stroke=&params->stroke();
            if(!stroke->paint_off())
            {
                CGPathDrawingMode   mode   = kCGPathFill;                        
                if(stroke->has_odd() && stroke->odd())
                {
                    mode = kCGPathEOFill;
                }                           
                
                if(stroke->has_color())
                {
                    CGContextSaveGState(context);
                    
                    CGFloat rgb[4] = {(CGFloat)stroke->color().r(),(CGFloat)stroke->color().g(),(CGFloat)stroke->color().b(), 1};
                    rgb[0] /= 255;
                    rgb[1] /= 255;
                    rgb[2] /= 255;
                    CGContextSetFillColorSpace(context, _colorSpace);
                    CGContextSetFillColor(context, rgb);
                    CGContextAddPath(context,path);
                    CGContextSetLineWidth(context, stroke->stroke_width());
                    CGContextReplacePathWithStrokedPath(context);
                    CGContextDrawPath(context, mode);
                    
                    CGContextRestoreGState(context);
                }else
                {
                    dbgLog(@"Unsupported stroke draw mode");
                }
            }                    
        }           
        if(needRestore)
        {
            CGContextRestoreGState(context);
        }        
    }
}

bool SVGRender::haveState(int stateNm)
{
    return _allStates.find(stateNm)!=_allStates.end();
}

bool SVGRender::isStateActive(int stateNm)
{
    return _activeStates.find(stateNm)!=_activeStates.end();
}


void SVGRender::setStateActive(int stateNm)
{
    if(haveState(stateNm))
    {
        _activeStates.insert(stateNm);
    }else
    {
        dbg_log("Use of undefined state %d",stateNm);
    }
}

void SVGRender::setStateInactive(int stateNm)
{
    _activeStates.erase(stateNm);
}

void SVGRender::setAllStatesInactive()
{
    _activeStates.clear();
}

CGAffineTransform SVGRender::transformForSize(CGSize size)
{
    CGAffineTransform rv = CGAffineTransformMakeTranslation(_root.frame().x(), _root.frame().y());
    
    double sx = size.width/_root.frame().w();
    double sy = size.height/_root.frame().h();
    if(sx>sy)
    {
        sx=sy;
    }else
    {
        sy=sx;
    }    
    
    rv = CGAffineTransformScale(rv, sx, sy);
    rv = CGAffineTransformTranslate(rv, -_root.bounds().x(), -_root.bounds().y());
    rv = CGAffineTransformScale(rv, _root.frame().w()/_root.bounds().w(), _root.frame().h()/_root.bounds().h());
    return rv;
}

void SVGRender::draw(CGContextRef context, CGSize size,  bool clearContext)
{
    CGContextSaveGState(context);
    if(clearContext)
        CGContextClearRect(context, CGRectMake(0, 0, size.width, size.height));
    
    CGAffineTransform transform = transformForSize(size);
    CGContextConcatCTM(context, transform);
    prepareToDraw(context, &_root.params());
    
    __block set<const ProtoSVGElement *> needRestoreSet;
    __block list<RenderContext> renderContextStack;
    
    renderContextStack.emplace_back(RenderContext());
    
    enumElements(^(const ProtoSVGElement *object) 
                 {
                     const ProtoSVGGeneralParams *params = &object->group();
                     
                     RenderContext rc = renderContextStack.back();
                     
                     if (params) {
                         bool needRestore = prepareToDraw(context, params);
                         if (needRestore)
                             needRestoreSet.insert(object);
                         
                         if (params->has_fill()) {
                             rc.fill.MergeFrom(params->fill());
                         
                             // убираем paint_off если ниже был установлен цвет
                             if (params->fill().has_color()) {
                                 rc.fill.clear_paint_off();
                             }
                         }
                     }
                     renderContextStack.push_back(rc);
                     
                     if(object->has_path())
                     {
                         drawPath(context, &object->path(), rc);
                     }
  
                     return true;
                 }, ^(const ProtoSVGElement *object) 
                 {
                     auto iter = needRestoreSet.find(object);
                     if( iter != needRestoreSet.end() )
                     {
                         CGContextRestoreGState(context);
                         needRestoreSet.erase(iter);
                     }
                     renderContextStack.pop_back();
                     return true;
                 });
    CGContextRestoreGState(context);
}    

UIImage *SVGRender::createUIImage(CGSize size, double scale)
{
    size.width  *= scale;
    size.height *= scale;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, size.width*4, 
                                                 colorSpace, kCGImageAlphaPremultipliedLast);
    if(context==nil)
    {
        dbgLog(@"Error creating context.");
    }
    CGColorSpaceRelease(colorSpace);
    
    draw(context,size);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    UIImage *rv = [UIImage imageWithCGImage:cgImage scale:scale orientation:UIImageOrientationDownMirrored];
    
    CGImageRelease(cgImage);
    CGContextRelease(context);
    return rv;
}

bool SVGRender::isGroupActive(const ProtoSVGGeneralParams *group)
{
    bool objectActive = true;
    if(group->has_id())
    {
        set<int> states = statesFromName(group->id());
        if(states.size()!=0)
        {
            objectActive = false;
            for(set<int>::const_iterator it = states.begin();it!=states.end();++it)
            {
                if(isStateActive(*it))
                {
                    objectActive = true;
                    break;
                }            
            }
        }
    }
    return objectActive;
}

bool SVGRender::isPointInside(CGPoint point, CGSize size)
{
    CGAffineTransform transform = transformForSize(size);
    transform = CGAffineTransformInvert(transform);
    point = CGPointApplyAffineTransform(point, transform);
    
    __block bool rv = false;
    
    enumElements(^(const ProtoSVGElement *object) 
    {
        if(object->has_path())
        {
            CGPathRef path = getCGPathForPath(&object->path());
            if(object->path().params().has_fill())
            {
                const ProtoSVGPaint *fill= &object->path().params().fill();
                if(!fill->paint_off())
                {
                    bool isOdd = false;
                    if(fill->has_odd() && fill->odd())
                    {
                        isOdd = true;
                    }
                    if(CGPathContainsPoint(path, nil, point, isOdd))
                    {
                        rv = true;
                        return false;
                    }
                }
            }
        }        
        return true;
    }, nil);
    return rv;
}


set<int>  SVGRender::statesAtPoint(CGPoint point, CGSize size,bool activeOnly)
{
    CGAffineTransform transform = transformForSize(size);
    transform = CGAffineTransformInvert(transform);
    point = CGPointApplyAffineTransform(point, transform);
    
    __block set<int> states;
    __block set<int> curStates;
    
    enumElements(^bool(const ProtoSVGElement *object) 
    {
        if(object->has_group())
        {
            if(object->group().has_id())
            {
                curStates = statesFromName(object->group().id());
            }else
            {
                curStates.clear();
            }
        }
        
        if(object->has_path() && curStates.size()!=0)
        {
            CGPathRef path = getCGPathForPath(&object->path());
            if(object->path().params().has_fill())
            {
                const ProtoSVGPaint *fill= &object->path().params().fill();
                if(!fill->paint_off())
                {
                    bool isOdd = false;
                    if(fill->has_odd() && fill->odd())
                    {
                        isOdd = true;
                    }
                    if(CGPathContainsPoint(path, nil, point, isOdd))
                    {
                        states.insert(curStates.begin(),curStates.end());
                    }
                }
            }
        }        
        return true;
    }, nil);
    
    if(!activeOnly)
    {
        return states;
    }
    
    set<int> rv;
    for (set<int>::const_iterator it=states.begin(); it!=states.end(); ++it)
    {
        if(isStateActive(*it))
        {
            rv.insert(*it);
        }
    }    
    return rv;    
}



bool SVGRender::enumElements(SVGRenderEnumBlock enumEnterBlock, 
                             SVGRenderEnumBlock enumExitBlock, 
                             const ProtoSVGElement *object, 
                             bool onlyActive)
{
    if (enumEnterBlock)
        enumEnterBlock(object);
    
    if(object->has_defs() && !onlyActive)
    {
        for (int i=0; i<object->defs().childs_size();i++)
        {
            if(!enumElements(enumEnterBlock, enumExitBlock, &object->defs().childs(i),onlyActive))
            {
                return false;
            }            
        }        
    }
    if(object->has_group() && (!onlyActive || isGroupActive(&object->group())))
    {
        for (int i=0; i<object->group().childs_size();i++)
        {
            if(!enumElements(enumEnterBlock, enumExitBlock, &object->group().childs(i),onlyActive))
            {
                return false;
            }            
        }
    }
    if (enumExitBlock)
        enumExitBlock(object);
    return true;
}

void SVGRender::enumElements(SVGRenderEnumBlock enumEnterBlock, 
                             SVGRenderEnumBlock enumExitBlock, bool onlyActive)
{
    for (int i=0; i<_root.params().childs_size();i++)
    {
        if(!enumElements(enumEnterBlock, enumExitBlock, &_root.params().childs(i),onlyActive))
        {
            break;
        }
    }    
}

CGRect SVGRender::getRect()
{
    return CGRectMake(_root.frame().x(), _root.frame().y(), _root.frame().w(), _root.frame().h());
}


